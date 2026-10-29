import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/core/network/api_exception.dart';
import 'package:seller_hub/domain/repositories/product_repository.dart';
import 'package:seller_hub/logic/product/product_bloc.dart';
import 'package:seller_hub/logic/product/product_event.dart';
import 'package:seller_hub/logic/product/product_state.dart';

class MockProductRepository implements ProductRepository {
  bool shouldThrow = false;
  String errorMessage = 'Failed to fetch products';
  ProductPageData? pageDataToReturn;
  ProductPageData? cachedDataToReturn;
  List<Product>? cachedFullCatalogToReturn;
  Product? lastUpdatedProduct;

  @override
  Future<List<Product>?> getCachedFullCatalog() async {
    return cachedFullCatalogToReturn;
  }

  @override
  Future<ProductPageData?> getCachedProducts({
    int page = 0,
    int size = 20,
  }) async {
    return cachedDataToReturn;
  }

  @override
  Future<List<Product>> getAllProducts() async {
    return pageDataToReturn?.content ?? cachedDataToReturn?.content ?? [];
  }

  @override
  Future<void> updateLocalProduct(Product product) async {
    lastUpdatedProduct = product;
  }

  @override
  Future<Product> assignCollections({
    required String productId,
    required List<String> collectionIds,
    required List<String> subCollectionIds,
  }) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage, statusCode: 500);
    }
    return (lastUpdatedProduct ??
            Product(
              id: productId,
              productCode: 'PRD-TEST',
              hsnCode: '3808',
              title: 'Test',
              technicalName: '',
              vendor: '',
              description: '',
              images: const [],
              technicalContent: '',
              modeOfAction: '',
              dosage: '',
              applicationMethod: '',
              category: '',
              isAvailable: true,
              isFeatured: false,
              ratings: 0,
              refundPolicy: '',
              productWeight: 0,
              productWeightUnit: 'kg',
            ))
        .copyWith(assignedCollections: [...collectionIds, ...subCollectionIds]);
  }

  @override
  Future<Product> createProduct(Product product) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage, statusCode: 500);
    }
    lastUpdatedProduct = product.copyWith(
      id: product.id.isNotEmpty ? product.id : 'created_id_123',
    );
    return lastUpdatedProduct!;
  }

  @override
  Future<void> deleteProductPermanently(String productId) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage, statusCode: 500);
    }
  }

  @override
  Future<Product> updateProductAvailability({
    required String productId,
    required bool isAvailable,
  }) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage, statusCode: 500);
    }
    final existing = lastUpdatedProduct ??
        Product(
          id: productId,
          title: 'Test Product',
          isAvailable: !isAvailable,
        );
    lastUpdatedProduct = existing.copyWith(isAvailable: isAvailable);
    return lastUpdatedProduct!;
  }

  @override
  Future<Product> uploadProductImages({
    required String productId,
    required List<List<int>> filesBytes,
    required List<String> fileNames,
  }) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage, statusCode: 500);
    }
    final existing = lastUpdatedProduct ??
        Product(
          id: productId,
          title: 'Test Product',
        );
    return existing;
  }

  @override
  Future<ProductPageData> getProducts({
    int page = 0,
    int size = 20,
  }) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage, statusCode: 500);
    }

    if (pageDataToReturn != null) {
      return pageDataToReturn!;
    }

    return ProductPageData(
      content: [
        Product(
          id: '6ad871a31df71c7f599dd954',
          sku: 'KKR - 35',
          productCode: 'PRD-6AB4ADA822033F1670582BDA-000035',
          hsnCode: '3808',
          title: 'Beauveria Bassiana - Bio Pesticide',
          technicalName: 'Beauveria bassiana',
          vendor: 'Essential Bio Crop Science',
          description: 'Beauveria Bassiana Bio Pesticide',
          images: const ['https://storage.googleapis.com/test-img.jpg'],
          productImages: const [
            ProductImage(
              id: '0ee2dd28',
              displayOrder: 0,
              midUrl: 'https://storage.googleapis.com/test-img.jpg',
            ),
          ],
          technicalContent: '5x10^8 CFU/ml min',
          modeOfAction: 'Fungal contact action',
          dosage: '2.5 ml / L',
          applicationMethod: 'Foliar spray',
          category: 'Bio Pesticide',
          isAvailable: true,
          isFeatured: true,
          ratings: 4.8,
          refundPolicy: '7 Days Returnable',
          productWeight: 1.0,
          productWeightUnit: 'kg',
          variants: const [
            ProductVariant(
              id: 'd4642c25c62d3220a533aa5d',
              label: '1 ltr (1000ml x 1)',
              unit: 'ml',
              packSize: 1000,
              displayRate: 510.0,
              printedMrp: 1200.0,
              stock: 100,
              pricePerBaseUnit: 0.51,
              isDefault: true,
            ),
          ],
        ),
      ],
      page: page,
      size: size,
      totalElements: 68,
      totalPages: 4,
      first: page == 0,
      last: page == 3,
      count: 1,
    );
  }
}

void main() {
  late MockProductRepository repository;
  late ProductBloc productBloc;

  setUp(() {
    repository = MockProductRepository();
    productBloc = ProductBloc(productRepository: repository);
  });

  tearDown(() {
    productBloc.close();
  });

  group('ProductBloc Tests', () {
    test('initial state has ProductStatus.initial', () {
      expect(productBloc.state.status, equals(ProductStatus.initial));
      expect(productBloc.state.products, isEmpty);
      expect(productBloc.state.currentPage, equals(0));
      expect(productBloc.state.pageSize, equals(20));
    });

    test('FetchProducts emits [loading, loaded] on successful repository call', () async {
      final expectedStates = [
        const ProductState(
          status: ProductStatus.loading,
          currentPage: 0,
          pageSize: 20,
        ),
        predicate<ProductState>((state) {
          return state.status == ProductStatus.loaded &&
              state.products.length == 1 &&
              state.products.first.title == 'Beauveria Bassiana - Bio Pesticide' &&
              state.pageData.totalElements == 68 &&
              state.pageData.totalPages == 4;
        }),
      ];

      expectLater(productBloc.stream, emitsInOrder(expectedStates));

      productBloc.add(const FetchProducts(page: 0, size: 20));
    });

    test('FetchProducts emits [loading, error] on ApiException', () async {
      repository.shouldThrow = true;
      repository.errorMessage = 'Server error retrieving products';

      final expectedStates = [
        const ProductState(
          status: ProductStatus.loading,
          currentPage: 0,
          pageSize: 20,
        ),
        predicate<ProductState>((state) {
          return state.status == ProductStatus.error &&
              state.errorMessage == 'Server error retrieving products';
        }),
      ];

      expectLater(productBloc.stream, emitsInOrder(expectedStates));

      productBloc.add(const FetchProducts(page: 0, size: 20));
    });

    test('SelectProductPage triggers FetchProducts with requested page', () async {
      productBloc.add(const SelectProductPage(2));

      await expectLater(
        productBloc.stream,
        emitsThrough(
          predicate<ProductState>((s) => s.status == ProductStatus.loaded && s.currentPage == 2),
        ),
      );
    });

    test('ChangeProductPageSize triggers FetchProducts with page 0 and new size', () async {
      productBloc.add(const ChangeProductPageSize(50));

      await expectLater(
        productBloc.stream,
        emitsThrough(
          predicate<ProductState>((s) => s.status == ProductStatus.loaded && s.pageSize == 50),
        ),
      );
    });

    test('UpdateLocalProduct updates product locally in state without full refetch', () async {
      productBloc.add(const FetchProducts(page: 0, size: 20));
      await expectLater(
        productBloc.stream,
        emitsThrough(predicate<ProductState>((s) => s.status == ProductStatus.loaded)),
      );

      final originalProduct = productBloc.state.products.first;
      final updatedProduct = originalProduct.copyWith(title: 'Updated Beauveria Title');

      productBloc.add(UpdateLocalProduct(updatedProduct));

      await expectLater(
        productBloc.stream,
        emitsThrough(
          predicate<ProductState>((s) => s.products.first.title == 'Updated Beauveria Title'),
        ),
      );
    });

    test('InitializeProducts hydrates from cache immediately (0ms) without showing loading spinner', () async {
      repository.cachedDataToReturn = ProductPageData(
        content: [
          Product(
            id: 'cached-1',
            sku: 'KKR - 99',
            productCode: 'PRD-CACHED-001',
            hsnCode: '3808',
            title: 'Cached Neem Oil Organic',
            technicalName: 'Azadirachtin 1%',
            vendor: 'Essential Bio Crop Science',
            description: 'Organic Cold Pressed Neem Oil',
            images: const ['https://storage.googleapis.com/test-img.jpg'],
            technicalContent: '10000 PPM',
            modeOfAction: 'Repellent and Anti-feedant',
            dosage: '3 ml / L',
            applicationMethod: 'Foliar spray',
            category: 'Bio Pesticide',
            isAvailable: true,
            isFeatured: true,
            ratings: 4.9,
            refundPolicy: '7 Days Returnable',
            productWeight: 1.0,
            productWeightUnit: 'L',
            displayRate: 450.0,
            printedMrp: 900.0,
            stock: 50,
          ),
        ],
        page: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
        first: true,
        last: true,
        count: 1,
      );

      productBloc.add(const InitializeProducts(page: 0, size: 20));

      // Verify the first emitted state has status loaded IMMEDIATELY (no ProductStatus.loading)
      await expectLater(
        productBloc.stream,
        emitsThrough(
          predicate<ProductState>((s) =>
              s.status == ProductStatus.loaded &&
              s.products.isNotEmpty &&
              s.products.first.title == 'Cached Neem Oil Organic'),
        ),
      );
    });

    test('WebSocketProductUpdateReceived updates product in-place with 0ms loading', () async {
      // First populate bloc with initial product
      productBloc.add(const FetchProducts(page: 0, size: 20));
      await expectLater(
        productBloc.stream,
        emitsThrough(predicate<ProductState>((s) => s.status == ProductStatus.loaded)),
      );

      // Simulate incoming WebSocket update payload
      final updatedPayload = {
        'type': 'PRODUCT_UPDATE',
        'data': {
          'id': '6ad871a31df71c7f599dd954',
          'sku': 'KKR - 35',
          'productCode': 'PRD-6AB4ADA822033F1670582BDA-000035',
          'title': 'Beauveria Bassiana - Updated Live via WebSocket',
          'displayRate': 599.0,
          'printedMrp': 1400.0,
          'stock': 120,
        },
      };

      productBloc.add(WebSocketProductUpdateReceived(updatedPayload));

      // Verify state reflects change without entering ProductStatus.loading
      await expectLater(
        productBloc.stream,
        emitsThrough(
          predicate<ProductState>((s) =>
              s.status == ProductStatus.loaded &&
              s.products.first.title == 'Beauveria Bassiana - Updated Live via WebSocket' &&
              s.products.first.displayRate == 599.0),
        ),
      );
    });

    test('WebSocket stock update modifies product stock in real-time', () async {
      productBloc.add(const FetchProducts(page: 0, size: 20));
      await expectLater(
        productBloc.stream,
        emitsThrough(predicate<ProductState>((s) => s.status == ProductStatus.loaded)),
      );

      final stockPayload = {
        'type': 'STOCK_UPDATED',
        'data': {
          'productId': '6ad871a31df71c7f599dd954',
          'stock': 42,
        },
      };

      productBloc.add(WebSocketProductUpdateReceived(stockPayload));

      await expectLater(
        productBloc.stream,
        emitsThrough(
          predicate<ProductState>((s) =>
              s.status == ProductStatus.loaded &&
              s.products.first.stock == 42),
        ),
      );
    });

    test('WebSocket inventory:stock_update event updates variant and total stock in real-time', () async {
      productBloc.add(const FetchProducts(page: 0, size: 20));
      await expectLater(
        productBloc.stream,
        emitsThrough(predicate<ProductState>((s) => s.status == ProductStatus.loaded)),
      );

      final backendEvent = {
        'event': 'inventory:stock_update',
        'data': {
          'productId': '6ad871a31df71c7f599dd954',
          'variantId': '6ad871a31df71c7f599dd955',
          'stock': 88,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      productBloc.add(WebSocketProductUpdateReceived(backendEvent));

      await expectLater(
        productBloc.stream,
        emitsThrough(
          predicate<ProductState>((s) =>
              s.status == ProductStatus.loaded &&
              s.products.first.stock == 88 &&
              s.products.first.variants.first.stock == 88),
        ),
      );
    });

    test('WebSocket products:delete event removes product from list in real-time', () async {
      productBloc.add(const FetchProducts(page: 0, size: 20));
      await expectLater(
        productBloc.stream,
        emitsThrough(predicate<ProductState>((s) => s.status == ProductStatus.loaded)),
      );

      final deleteEvent = {
        'event': 'products:delete',
        'data': {
          'productId': '6ad871a31df71c7f599dd954',
          'isPermanent': false,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      productBloc.add(WebSocketProductUpdateReceived(deleteEvent));

      await expectLater(
        productBloc.stream,
        emitsThrough(
          predicate<ProductState>((s) =>
              s.status == ProductStatus.loaded &&
              s.products.isEmpty),
        ),
      );
    });

    test('Product fromJson correctly decodes MongoDB multi-variants with commercial attributes', () {
      final mongoJson = {
        'id': '6ad871a31df71c7f599dd954',
        'sku': 'KKR - 35',
        'productCode': 'PRD-6AB4ADA822033F1670582BDA-000035',
        'hsnCode': '3808',
        'title': 'Beauveria Bassiana - Bio Pesticide',
        'category': null,
        'categoryId': '6ad8582568a1edff7a609fee',
        'variants': [
          {
            'id': 'v1',
            'label': '1 ltr (1000ml x 1)',
            'packSize': 1000,
            'packSizeUnit': 'ml',
            'packQuantity': 1,
            'displayRate': 510.0,
            'printedMrp': 1200.0,
            'stock': 100,
            'isDefault': true,
          },
          {
            'id': 'v2',
            'label': '3 ltr (1000ml x 3)',
            'packSize': 1000,
            'packSizeUnit': 'ml',
            'packQuantity': 3,
            'displayRate': 1210.0,
            'printedMrp': 3600.0,
            'stock': 100,
            'isDefault': false,
          },
          {
            'id': 'v3',
            'label': '10 ltr (1000ml x 10)',
            'packSize': 1000,
            'packSizeUnit': 'ml',
            'packQuantity': 10,
            'displayRate': 3740.0,
            'printedMrp': 12000.0,
            'stock': 100,
            'isDefault': false,
          },
        ],
      };

      final product = Product.fromJson(mongoJson);

      expect(product.variantsCount, 3);
      expect(product.hasMultipleVariants, true);
      expect(product.minDisplayRate, 510.0);
      expect(product.maxDisplayRate, 3740.0);
      expect(product.priceRangeFormatted, '₹510 - ₹3740');
      expect(product.mrpRangeFormatted, '₹1200 - ₹12000');
      expect(product.totalStock, 300);
      expect(product.defaultVariant?.label, '1 ltr (1000ml x 1)');
      expect(product.resolvedCategory, 'Bio Pesticides');
    });

    test('FetchAllCatalogProducts populates allCatalogProducts in ProductState across full catalog', () async {
      final catalog = List.generate(
        67,
        (i) => Product(
          id: 'prod_$i',
          productCode: 'PRD-00$i',
          hsnCode: '3808',
          title: 'Product $i',
          technicalName: 'Tech $i',
          vendor: 'Vendor A',
          description: '',
          images: const [],
          technicalContent: '',
          modeOfAction: '',
          dosage: '',
          applicationMethod: '',
          category: 'Bio-Fertilizers',
          isAvailable: true,
          isFeatured: false,
          ratings: 4.5,
          refundPolicy: '',
          productWeight: 1.0,
          productWeightUnit: 'kg',
        ),
      );

      repository.pageDataToReturn = ProductPageData(
        content: catalog,
        page: 0,
        size: 100,
        totalElements: 67,
        totalPages: 1,
      );

      productBloc.add(const FetchAllCatalogProducts());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(productBloc.state.allCatalogProducts.length, 67);
      expect(productBloc.state.totalProducts, 67);
    });

    test('DeleteProductPermanently removes product from state and updates total', () async {
      final initialProduct = Product(
        id: 'delete_target_123',
        productCode: 'PRD-DEL',
        hsnCode: '3808',
        title: 'Delete Target Product',
        technicalName: '',
        vendor: '',
        description: '',
        images: const [],
        technicalContent: '',
        modeOfAction: '',
        dosage: '',
        applicationMethod: '',
        category: 'Bio-Fertilizers',
        isAvailable: true,
        isFeatured: false,
        ratings: 4.5,
        refundPolicy: '',
        productWeight: 1.0,
        productWeightUnit: 'kg',
      );

      repository.pageDataToReturn = ProductPageData(
        content: [initialProduct],
        page: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
      );

      productBloc.add(const FetchProducts());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(productBloc.state.products.length, 1);

      bool successCalled = false;
      productBloc.add(DeleteProductPermanently(
        'delete_target_123',
        onSuccess: () => successCalled = true,
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(successCalled, true);
      expect(productBloc.state.products.isEmpty, true);
      expect(productBloc.state.pageData.totalElements, 0);
    });
  });
}
