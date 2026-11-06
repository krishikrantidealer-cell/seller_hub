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
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProductPermanently>(_onDeleteProductPermanently);
    on<DeleteMultipleProductsPermanently>(_onDeleteMultipleProductsPermanently);
    on<ToggleProductAvailability>(_onToggleProductAvailability);
    on<SetDefaultProductVariant>(_onSetDefaultProductVariant);
    on<UploadProductImages>(_onUploadProductImages);

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
    final cachedFull = await productRepository.getCachedFullCatalog();

    if (cached != null && cached.content.isNotEmpty) {
      final bool hasExpired = cached.hasExpiredImages;

      emit(state.copyWith(
        status: ProductStatus.loaded,
        pageData: cached,
        currentPage: event.page,
        pageSize: event.size,
        allCatalogProducts: cachedFull ?? const [],
        isBackgroundSyncing: true,
      ));

      // 2. Refresh from server. If cached signed URLs are expired, actively refresh
      add(FetchProducts(
        page: event.page,
        size: event.size,
        isBackground: !hasExpired,
      ));
    } else {
      if (cachedFull != null && cachedFull.isNotEmpty) {
        emit(state.copyWith(allCatalogProducts: cachedFull));
      }
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

      final allCatalog = state.allCatalogProducts.isNotEmpty
          ? state.allCatalogProducts
          : (pageData.totalElements > 0 && pageData.totalElements <= pageData.content.length ? pageData.content : null);

      emit(state.copyWith(
        status: ProductStatus.loaded,
        pageData: pageData,
        currentPage: event.page,
        pageSize: event.size,
        allCatalogProducts: allCatalog,
        errorMessage: null,
        isBackgroundSyncing: false,
      ));

      if (state.allCatalogProducts.isEmpty && pageData.totalElements > pageData.content.length) {
        add(const FetchAllCatalogProducts());
      }
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

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<ProductState> emit,
  ) async {
    final previousState = state;
    final Product? previousProduct = state.products.cast<Product?>().firstWhere(
      (p) => (p?.id.isNotEmpty == true && p!.id == event.product.id) ||
             (p?.productCode.isNotEmpty == true && p!.productCode == event.product.productCode),
      orElse: () => null,
    );

    // 1. Optimistic update in-memory and local database cache (0ms instant UI responsiveness)
    final updatedList = List<Product>.from(state.products);
    final index = updatedList.indexWhere((p) =>
        (p.id.isNotEmpty && p.id == event.product.id) ||
        (p.productCode.isNotEmpty && p.productCode == event.product.productCode) ||
        (p.sku.isNotEmpty && p.sku == event.product.sku));

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

    await productRepository.updateLocalProduct(event.product);

    List<Product>? updatedAll;
    if (state.allCatalogProducts.isNotEmpty) {
      final allList = List<Product>.from(state.allCatalogProducts);
      final aIdx = allList.indexWhere((p) =>
          (p.id.isNotEmpty && p.id == event.product.id) ||
          (p.productCode.isNotEmpty && p.productCode == event.product.productCode) ||
          (p.sku.isNotEmpty && p.sku == event.product.sku));
      if (aIdx != -1) {
        allList[aIdx] = event.product;
      } else {
        allList.insert(0, event.product);
      }
      updatedAll = allList;
    }

    emit(state.copyWith(
      status: ProductStatus.loaded,
      pageData: updatedPageData,
      allCatalogProducts: updatedAll ?? state.allCatalogProducts,
    ));

    // 2. Persist to backend database via PATCH /api/v1/admin/products/{productId}
    if (event.product.id.isNotEmpty) {
      try {
        final serverUpdated = await productRepository.updateProduct(event.product);

        final finalList = List<Product>.from(state.products);
        final fIdx = finalList.indexWhere((p) =>
            (p.id.isNotEmpty && p.id == serverUpdated.id) ||
            (p.productCode.isNotEmpty && p.productCode == serverUpdated.productCode) ||
            (p.sku.isNotEmpty && p.sku == serverUpdated.sku));
        if (fIdx != -1) {
          finalList[fIdx] = serverUpdated;
        } else {
          finalList.insert(0, serverUpdated);
        }

        final finalPageData = ProductPageData(
          content: finalList,
          page: state.pageData.page,
          size: state.pageData.size,
          totalElements: state.pageData.totalElements,
          totalPages: state.pageData.totalPages,
          first: state.pageData.first,
          last: state.pageData.last,
          count: finalList.length,
        );

        List<Product>? finalAll;
        if (state.allCatalogProducts.isNotEmpty) {
          final allList = List<Product>.from(state.allCatalogProducts);
          final aIdx = allList.indexWhere((p) =>
              (p.id.isNotEmpty && p.id == serverUpdated.id) ||
              (p.productCode.isNotEmpty && p.productCode == serverUpdated.productCode) ||
              (p.sku.isNotEmpty && p.sku == serverUpdated.sku));
          if (aIdx != -1) {
            allList[aIdx] = serverUpdated;
          } else {
            allList.insert(0, serverUpdated);
          }
          finalAll = allList;
        }

        _webSocketService.broadcastProductChange(serverUpdated);

        emit(state.copyWith(
          status: ProductStatus.loaded,
          pageData: finalPageData,
          allCatalogProducts: finalAll ?? state.allCatalogProducts,
          errorMessage: null,
        ));

        event.onSuccess?.call(serverUpdated);
      } catch (e) {
        // Rollback local cache and state on server failure
        if (previousProduct != null) {
          await productRepository.updateLocalProduct(previousProduct);
        }
        final message = e is ApiException ? e.message : 'Failed to update product: $e';
        emit(previousState.copyWith(
          errorMessage: message,
        ));
        event.onError?.call(message);
      }
    } else {
      event.onSuccess?.call(event.product);
    }
  }

  Future<void> _onDeleteProductPermanently(
    DeleteProductPermanently event,
    Emitter<ProductState> emit,
  ) async {
    final previousState = state;
    bool matches(Product p) =>
        (p.id.isNotEmpty && (p.id == event.productId || p.id == event.productCode || p.id == event.sku)) ||
        (p.productCode.isNotEmpty && (p.productCode == event.productId || p.productCode == event.productCode || p.productCode == event.sku)) ||
        (p.sku.isNotEmpty && (p.sku == event.productId || p.sku == event.productCode || p.sku == event.sku));

    final currentList = List<Product>.from(state.pageData.content)..removeWhere(matches);
    final currentAll = List<Product>.from(state.allCatalogProducts)..removeWhere(matches);

    final newTotal = state.pageData.totalElements > 0
        ? state.pageData.totalElements - 1
        : currentList.length;
    final safePageSize = state.pageData.size > 0 ? state.pageData.size : 20;

    final updatedPageData = ProductPageData(
      content: currentList,
      page: state.pageData.page,
      size: state.pageData.size,
      totalElements: newTotal,
      totalPages: (newTotal / safePageSize).ceil().clamp(1, 999999),
      first: state.pageData.first,
      last: state.pageData.last,
      count: currentList.length,
    );

    // 1. Optimistic instant emission (0ms) so product table and SKU counts update immediately
    emit(state.copyWith(
      status: ProductStatus.loaded,
      pageData: updatedPageData,
      allCatalogProducts: currentAll,
      errorMessage: null,
    ));

    event.onSuccess?.call();

    try {
      await productRepository.deleteProductPermanently(event.productId);
    } catch (e) {
      // Revert if API fails
      final message = e is ApiException ? e.message : 'Failed to delete product: $e';
      emit(previousState.copyWith(
        errorMessage: message,
      ));
      event.onError?.call(message);
    }
  }

  Future<void> _onDeleteMultipleProductsPermanently(
    DeleteMultipleProductsPermanently event,
    Emitter<ProductState> emit,
  ) async {
    final targetSet = event.productIds.toSet();

    bool matches(Product p) =>
        (p.id.isNotEmpty && targetSet.contains(p.id)) ||
        (p.productCode.isNotEmpty && targetSet.contains(p.productCode)) ||
        (p.sku.isNotEmpty && targetSet.contains(p.sku));

    final currentList = List<Product>.from(state.pageData.content)..removeWhere(matches);
    final currentAll = List<Product>.from(state.allCatalogProducts)..removeWhere(matches);

    final removedCount = state.pageData.content.length - currentList.length;
    final newTotal = state.pageData.totalElements > 0
        ? (state.pageData.totalElements - removedCount).clamp(0, 999999)
        : currentList.length;
    final safePageSize = state.pageData.size > 0 ? state.pageData.size : 20;

    final updatedPageData = ProductPageData(
      content: currentList,
      page: state.pageData.page,
      size: state.pageData.size,
      totalElements: newTotal,
      totalPages: (newTotal / safePageSize).ceil().clamp(1, 999999),
      first: state.pageData.first,
      last: state.pageData.last,
      count: currentList.length,
    );

    // 1. Optimistic instant emission (0ms) so product table and SKU counts update immediately
    emit(state.copyWith(
      status: ProductStatus.loaded,
      pageData: updatedPageData,
      allCatalogProducts: currentAll,
      errorMessage: null,
    ));

    event.onSuccess?.call(targetSet.length);

    // 2. Perform atomic deletion in background via unified endpoint
    try {
      await productRepository.deleteMultipleProductsPermanently(event.productIds);
    } catch (e) {
      final message = e is ApiException ? e.message : 'Failed to delete products: $e';
      emit(state.copyWith(
        errorMessage: message,
      ));
      event.onError?.call(message);
    }
  }

  Future<void> _onToggleProductAvailability(
    ToggleProductAvailability event,
    Emitter<ProductState> emit,
  ) async {
    final previousState = state;

    // 1. Optimistic immediate toggle (0ms)
    final currentList = List<Product>.from(state.pageData.content);
    final idx = currentList.indexWhere((p) => p.id == event.productId || p.productCode == event.productId);
    if (idx != -1) {
      currentList[idx] = currentList[idx].copyWith(isAvailable: event.isAvailable);
    }

    final currentAll = List<Product>.from(state.allCatalogProducts);
    final allIdx = currentAll.indexWhere((p) => p.id == event.productId || p.productCode == event.productId);
    if (allIdx != -1) {
      currentAll[allIdx] = currentAll[allIdx].copyWith(isAvailable: event.isAvailable);
    }

    final optimisticPageData = ProductPageData(
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
      pageData: optimisticPageData,
      allCatalogProducts: currentAll,
    ));

    try {
      final updated = await productRepository.updateProductAvailability(
        productId: event.productId,
        isAvailable: event.isAvailable,
      );

      final confirmedList = List<Product>.from(state.pageData.content);
      final cIdx = confirmedList.indexWhere((p) => p.id == event.productId || p.productCode == event.productId);
      if (cIdx != -1) {
        confirmedList[cIdx] = updated;
      }

      final confirmedAll = List<Product>.from(state.allCatalogProducts);
      final caIdx = confirmedAll.indexWhere((p) => p.id == event.productId || p.productCode == event.productId);
      if (caIdx != -1) {
        confirmedAll[caIdx] = updated;
      }

      final confirmedPageData = ProductPageData(
        content: confirmedList,
        page: state.pageData.page,
        size: state.pageData.size,
        totalElements: state.pageData.totalElements,
        totalPages: state.pageData.totalPages,
        first: state.pageData.first,
        last: state.pageData.last,
        count: confirmedList.length,
      );

      emit(state.copyWith(
        status: ProductStatus.loaded,
        pageData: confirmedPageData,
        allCatalogProducts: confirmedAll,
        errorMessage: null,
      ));

      event.onSuccess?.call(updated);
    } catch (e) {
      final message = e is ApiException ? e.message : 'Failed to update availability: $e';
      emit(previousState.copyWith(errorMessage: message));
      event.onError?.call(message);
    }
  }

  Future<void> _onUploadProductImages(
    UploadProductImages event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final updated = await productRepository.uploadProductImages(
        productId: event.productId,
        filesBytes: event.filesBytes,
        fileNames: event.fileNames,
      );

      final currentList = List<Product>.from(state.pageData.content);
      final idx = currentList.indexWhere((p) => p.id == event.productId || p.productCode == event.productId);
      if (idx != -1) {
        currentList[idx] = updated;
      }

      final currentAll = List<Product>.from(state.allCatalogProducts);
      final allIdx = currentAll.indexWhere((p) => p.id == event.productId || p.productCode == event.productId);
      if (allIdx != -1) {
        currentAll[allIdx] = updated;
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
        allCatalogProducts: currentAll,
        errorMessage: null,
      ));

      event.onSuccess?.call(updated);
    } catch (e) {
      final message = e is ApiException ? e.message : 'Failed to upload images: $e';
      emit(state.copyWith(errorMessage: message));
      event.onError?.call(message);
    }
  }

  Future<void> _onSetDefaultProductVariant(
    SetDefaultProductVariant event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final updated = await productRepository.setDefaultVariant(
        productId: event.productId,
        variantId: event.variantId,
        isDefault: event.isDefault,
      );

      final currentList = List<Product>.from(state.pageData.content);
      final idx = currentList.indexWhere((p) => p.id == updated.id || p.productCode == updated.id);
      if (idx != -1) {
        currentList[idx] = updated;
      }

      final currentAll = List<Product>.from(state.allCatalogProducts);
      final allIdx = currentAll.indexWhere((p) => p.id == updated.id || p.productCode == updated.id);
      if (allIdx != -1) {
        currentAll[allIdx] = updated;
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
        allCatalogProducts: currentAll,
        errorMessage: null,
      ));

      event.onSuccess?.call(updated);
    } catch (e) {
      final message = e is ApiException ? e.message : 'Failed to set default variant: $e';
      emit(state.copyWith(errorMessage: message));
      event.onError?.call(message);
    }
  }
}
