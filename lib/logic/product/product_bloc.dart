import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/product.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/websocket_service.dart';
import '../../domain/repositories/product_repository.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository productRepository;
  final WebSocketService _webSocketService;
  StreamSubscription? _wsSubscription;

  ProductBloc({
    required this.productRepository,
    WebSocketService? webSocketService,
  })  : _webSocketService = webSocketService ?? WebSocketService(),
        super(const ProductState()) {
    on<InitializeProducts>(_onInitializeProducts);
    on<FetchProducts>(_onFetchProducts);
    on<SelectProductPage>(_onSelectProductPage);
    on<ChangeProductPageSize>(_onChangeProductPageSize);
    on<UpdateLocalProduct>(_onUpdateLocalProduct);
    on<WebSocketProductUpdateReceived>(_onWebSocketProductUpdateReceived);

    // Subscribe to live WebSocket product and inventory events
    _wsSubscription = _webSocketService.productUpdates.listen((payload) {
      add(WebSocketProductUpdateReceived(payload));
    });
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onInitializeProducts(
    InitializeProducts event,
    Emitter<ProductState> emit,
  ) async {
    // 1. Immediately hydrate with locally cached products (0ms instant render on restart)
    final cached = await productRepository.getCachedProducts(
      page: event.page,
      size: event.size,
    );

    if (cached != null && cached.content.isNotEmpty) {
      emit(state.copyWith(
        status: ProductStatus.loaded,
        pageData: cached,
        currentPage: event.page,
        pageSize: event.size,
        isBackgroundSyncing: true,
      ));

      // 2. Perform silent background freshness sync without blocking user interaction
      add(FetchProducts(
        page: event.page,
        size: event.size,
        isBackground: true,
      ));
    } else {
      // No local cache yet: standard initial fetch with loading indicator
      add(FetchProducts(
        page: event.page,
        size: event.size,
        isBackground: false,
      ));
    }
  }

  Future<void> _onFetchProducts(
    FetchProducts event,
    Emitter<ProductState> emit,
  ) async {
    final hasExistingData = state.status == ProductStatus.loaded && state.products.isNotEmpty;

    if (!event.isBackground && !hasExistingData) {
      emit(state.copyWith(
        status: ProductStatus.loading,
        currentPage: event.page,
        pageSize: event.size,
        errorMessage: null,
      ));
    } else if (event.isBackground) {
      emit(state.copyWith(
        isBackgroundSyncing: true,
      ));
    }

    try {
      final pageData = await productRepository.getProducts(
        page: event.page,
        size: event.size,
      );

      emit(state.copyWith(
        status: ProductStatus.loaded,
        pageData: pageData,
        currentPage: event.page,
        pageSize: event.size,
        errorMessage: null,
        isBackgroundSyncing: false,
      ));
    } on ApiException catch (e) {
      if (!hasExistingData) {
        emit(state.copyWith(
          status: ProductStatus.error,
          errorMessage: e.message,
          isBackgroundSyncing: false,
        ));
      } else {
        // Keep existing loaded data on silent background failures
        emit(state.copyWith(
          isBackgroundSyncing: false,
        ));
      }
    } catch (e) {
      if (!hasExistingData) {
        emit(state.copyWith(
          status: ProductStatus.error,
          errorMessage: 'Failed to fetch products: ${e.toString()}',
          isBackgroundSyncing: false,
        ));
      } else {
        emit(state.copyWith(
          isBackgroundSyncing: false,
        ));
      }
    }
  }

  Future<void> _onSelectProductPage(
    SelectProductPage event,
    Emitter<ProductState> emit,
  ) async {
    if (event.page == state.currentPage && state.status == ProductStatus.loaded) {
      return;
    }
    add(FetchProducts(page: event.page, size: state.pageSize));
  }

  Future<void> _onChangeProductPageSize(
    ChangeProductPageSize event,
    Emitter<ProductState> emit,
  ) async {
    add(FetchProducts(page: 0, size: event.size));
  }

  void _onUpdateLocalProduct(
    UpdateLocalProduct event,
    Emitter<ProductState> emit,
  ) {
    final updatedList = List<Product>.from(state.products);
    final index = updatedList.indexWhere((p) =>
        (p.id.isNotEmpty && p.id == event.product.id) ||
        (p.productCode.isNotEmpty && p.productCode == event.product.productCode));

    if (index != -1) {
      updatedList[index] = event.product;
    } else {
      updatedList.insert(0, event.product);
    }

    final updatedPageData = ProductPageData(
      content: updatedList,
      page: state.pageData.page,
      size: state.pageData.size,
      totalElements: state.pageData.totalElements,
      totalPages: state.pageData.totalPages,
      first: state.pageData.first,
      last: state.pageData.last,
      count: updatedList.length,
    );

    // Persist to local cache immediately
    productRepository.updateLocalProduct(event.product);

    // Broadcast change across WebSocket to other connected clients
    if (event.broadcastWs) {
      _webSocketService.broadcastProductChange(event.product);
    }

    // 0ms instant UI update without any loading screen
    emit(state.copyWith(
      status: ProductStatus.loaded,
      pageData: updatedPageData,
    ));
  }

  void _onWebSocketProductUpdateReceived(
    WebSocketProductUpdateReceived event,
    Emitter<ProductState> emit,
  ) {
    try {
      final payload = event.payload;
      final rawData = payload['data'] ?? payload['product'];

      if (rawData is Map<String, dynamic>) {
        if (rawData.containsKey('title') || rawData.containsKey('productCode') || rawData.containsKey('variants')) {
          final product = Product.fromJson(rawData);
          // Update in-place with 0ms loading
          add(UpdateLocalProduct(product, broadcastWs: false));
          return;
        }

        // Live inventory stock update
        if (rawData.containsKey('productId') && rawData.containsKey('stock')) {
          final pId = rawData['productId'].toString();
          final newStock = int.tryParse(rawData['stock'].toString()) ?? 0;
          final idx = state.products.indexWhere((p) => p.id == pId);
          if (idx != -1) {
            final oldP = state.products[idx];
            final updatedP = oldP.copyWith(stock: newStock);
            add(UpdateLocalProduct(updatedP, broadcastWs: false));
            return;
          }
        }
      }

      // If general refresh signal (e.g. PRODUCTS_UPDATE): background sync without spinner
      add(FetchProducts(
        page: state.currentPage,
        size: state.pageSize,
        isBackground: true,
      ));
    } catch (_) {
      add(FetchProducts(
        page: state.currentPage,
        size: state.pageSize,
        isBackground: true,
      ));
    }
  }
}
