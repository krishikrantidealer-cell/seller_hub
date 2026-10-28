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
    on<AssignProductCollections>(_onAssignProductCollections);
    on<FetchAllCatalogProducts>(_onFetchAllCatalogProducts);
    on<CreateProduct>(_onCreateProduct);

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
      final bool hasExpired = cached.hasExpiredImages;

      emit(state.copyWith(
        status: ProductStatus.loaded,
        pageData: cached,
        currentPage: event.page,
        pageSize: event.size,
        isBackgroundSyncing: true,
      ));

      // 2. Refresh from server. If cached signed URLs are expired, actively refresh
      add(FetchProducts(
        page: event.page,
        size: event.size,
        isBackground: !hasExpired,
      ));
    } else {
      // No local cache yet: standard initial fetch with loading indicator
      add(FetchProducts(
        page: event.page,
        size: event.size,
        isBackground: false,
      ));
    }

    // Hydrate complete catalog across all pages for bulk assignment, dialogs, and filters
    add(const FetchAllCatalogProducts());
  }

  Future<void> _onFetchAllCatalogProducts(
    FetchAllCatalogProducts event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final all = await productRepository.getAllProducts();
      if (all.isNotEmpty) {
        emit(state.copyWith(allCatalogProducts: all));
      }
    } catch (_) {}
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

    // Also keep allCatalogProducts in sync
    List<Product>? updatedAll;
    if (state.allCatalogProducts.isNotEmpty) {
      final allList = List<Product>.from(state.allCatalogProducts);
      final aIdx = allList.indexWhere((p) =>
          (p.id.isNotEmpty && p.id == event.product.id) ||
          (p.productCode.isNotEmpty && p.productCode == event.product.productCode));
      if (aIdx != -1) {
        allList[aIdx] = event.product;
      } else {
        allList.insert(0, event.product);
      }
      updatedAll = allList;
    }

    // 0ms instant UI update without any loading screen
    emit(state.copyWith(
      status: ProductStatus.loaded,
      pageData: updatedPageData,
      allCatalogProducts: updatedAll ?? state.allCatalogProducts,
    ));
  }

  void _onWebSocketProductUpdateReceived(
    WebSocketProductUpdateReceived event,
    Emitter<ProductState> emit,
  ) {
    try {
      final payload = event.payload;
      final eventName = payload['event'] as String?;
      final rawData = payload['data'] ?? payload['product'] ?? payload;

      // 1. Live Inventory Stock Update event (inventory:stock_update)
      if (eventName == 'inventory:stock_update' ||
          (rawData is Map && rawData.containsKey('productId') && rawData.containsKey('stock'))) {
        final dataMap = rawData is Map ? Map<String, dynamic>.from(rawData) : <String, dynamic>{};
        final pId = (dataMap['productId'] ?? '').toString();
        final variantId = dataMap['variantId']?.toString();
        final newStock = int.tryParse(dataMap['stock'].toString()) ?? 0;

        final idx = state.products.indexWhere(
          (p) => (p.id.isNotEmpty && p.id == pId) || (p.productCode.isNotEmpty && p.productCode == pId),
        );

        if (idx != -1) {
          final oldP = state.products[idx];
          List<ProductVariant> updatedVariants = oldP.variants;
          if (variantId != null && variantId.isNotEmpty && oldP.variants.isNotEmpty) {
            updatedVariants = oldP.variants.map((v) {
              if (v.id == variantId) {
                return v.copyWith(stock: newStock);
              }
              return v;
            }).toList();
          }

          final updatedP = oldP.copyWith(
            stock: newStock,
            variants: updatedVariants,
          );
          add(UpdateLocalProduct(updatedP, broadcastWs: false));
          return;
        }
      }

      // 2. Product Deleted event (products:delete)
      if (eventName == 'products:delete' && rawData is Map) {
        final pId = (rawData['productId'] ?? '').toString();
        if (pId.isNotEmpty) {
          final updatedList = state.products.where((p) => p.id != pId && p.productCode != pId).toList();
          emit(state.copyWith(
            pageData: ProductPageData(
              content: updatedList,
              page: state.pageData.page,
              size: state.pageData.size,
              totalElements: (state.pageData.totalElements - 1).clamp(0, 999999),
              totalPages: state.pageData.totalPages,
              first: state.pageData.first,
              last: state.pageData.last,
              count: updatedList.length,
            ),
          ));
          return;
        }
      }

      // 3. Product Updated entity event (products:update)
      if (rawData is Map<String, dynamic>) {
        if (rawData.containsKey('title') || rawData.containsKey('productCode') || rawData.containsKey('variants')) {
          final product = Product.fromJson(rawData);
          add(UpdateLocalProduct(product, broadcastWs: false));
          return;
        }
      }

      // 4. Products refresh or catalog invalidated event (products:refresh)
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

  Future<void> _onAssignProductCollections(
    AssignProductCollections event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(
      isAssigningCollections: true,
      assignCollectionsError: null,
      clearLastAssignedProduct: true,
    ));

    try {
      final updatedProduct = await productRepository.assignCollections(
        productId: event.productId,
        collectionIds: event.collectionIds,
        subCollectionIds: event.subCollectionIds,
      );

      final currentList = List<Product>.from(state.products);
      final index = currentList.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        currentList[index] = updatedProduct;
      } else {
        currentList.insert(0, updatedProduct);
      }

      final updatedPageData = ProductPageData(
        content: currentList,
        page: state.pageData.page,
        size: state.pageData.size,
        totalElements: state.pageData.totalElements,
        totalPages: state.pageData.totalPages,
        first: state.pageData.first,
        last: state.pageData.last,
        count: currentList.length,
      );

      emit(state.copyWith(
        status: ProductStatus.loaded,
        pageData: updatedPageData,
        isAssigningCollections: false,
        lastAssignedProduct: updatedProduct,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isAssigningCollections: false,
        assignCollectionsError: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isAssigningCollections: false,
        assignCollectionsError: 'Failed to assign collections: $e',
      ));
    }
  }

  Future<void> _onCreateProduct(
    CreateProduct event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final createdProduct = await productRepository.createProduct(event.product);
      final currentList = List<Product>.from(state.pageData.content);
      currentList.removeWhere((p) => p.id == createdProduct.id || (p.sku.isNotEmpty && p.sku == createdProduct.sku));
      currentList.insert(0, createdProduct);

      final currentAll = List<Product>.from(state.allCatalogProducts);
      currentAll.removeWhere((p) => p.id == createdProduct.id || (p.sku.isNotEmpty && p.sku == createdProduct.sku));
      currentAll.insert(0, createdProduct);

      final updatedPageData = ProductPageData(
        content: currentList,
        page: state.pageData.page,
        size: state.pageData.size,
        totalElements: state.pageData.totalElements + 1,
        totalPages: state.pageData.totalPages,
        first: state.pageData.first,
        last: state.pageData.last,
        count: currentList.length,
      );

      emit(state.copyWith(
        status: ProductStatus.loaded,
        pageData: updatedPageData,
        allCatalogProducts: currentAll,
        errorMessage: null,
      ));

      event.onSuccess?.call(createdProduct);
    } catch (e) {
      final message = e is ApiException ? e.message : 'Failed to create product: $e';
      emit(state.copyWith(
        errorMessage: message,
      ));
      event.onError?.call(message);
    }
  }
}
