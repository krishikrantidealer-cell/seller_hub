import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/domain/repositories/seller_product_repository.dart';
import 'package:seller_hub/logic/seller_catalog/seller_catalog_bloc.dart';
import 'package:seller_hub/logic/seller_catalog/seller_catalog_event.dart';
import 'package:seller_hub/logic/seller_catalog/seller_catalog_state.dart';

class FakeSellerProductRepository implements SellerProductRepository {
  List<Product> products = List.from(Product.sampleProducts);
  bool shouldThrow = false;

  @override
  Future<List<Product>> getSellerProducts({int page = 0, int size = 20}) async {
    if (shouldThrow) throw Exception('Network error');
    return products;
  }

  @override
  Future<Product> submitProductListing(Product product) async {
    if (shouldThrow) throw Exception('Submission failed');
    products.insert(0, product);
    return product;
  }

  @override
  Future<Product> updateProductListing(Product product) async {
    if (shouldThrow) throw Exception('Update failed');
    final idx = products.indexWhere((p) => p.productCode == product.productCode);
    if (idx != -1) {
      products[idx] = product;
    }
    return product;
  }

  @override
  Future<List<String>> uploadProductImages(String productId, List<String> filePaths) async {
    return ['https://example.com/image1.jpg'];
  }
}

void main() {
  group('SellerCatalogBloc Tests', () {
    late FakeSellerProductRepository fakeRepo;
    late SellerCatalogBloc bloc;

    setUp(() {
      fakeRepo = FakeSellerProductRepository();
      bloc = SellerCatalogBloc(repository: fakeRepo);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is SellerCatalogInitial', () {
      expect(bloc.state, isA<SellerCatalogInitial>());
    });

    test('FetchSellerProductsEvent fetches products and emits Loaded state', () async {
      final expectedStates = [
        isA<SellerCatalogLoading>(),
        isA<SellerCatalogLoaded>().having((s) => s.products.length, 'products.length', fakeRepo.products.length),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const FetchSellerProductsEvent());
    });

    test('SubmitProductListingEvent adds product and emits ActionSuccess then Loaded', () async {
      final newProduct = Product.sampleProducts.first.copyWith(
        id: 'new_prod_99',
        productCode: 'PROD-NEW-99',
        title: 'New Organic Fertilizer',
        sellerId: '6ab4ada822033f1670582bda',
      );

      final expectedStates = [
        isA<SellerCatalogSubmitting>(),
        isA<SellerCatalogActionSuccess>().having((s) => s.affectedProduct.productCode, 'productCode', 'PROD-NEW-99'),
        isA<SellerCatalogLoaded>().having((s) => s.products.first.productCode, 'firstProductCode', 'PROD-NEW-99'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(SubmitProductListingEvent(newProduct));
    });

    test('UpdateProductListingEvent updates product and emits ActionSuccess then Loaded', () async {
      bloc.emit(SellerCatalogLoaded(products: List.from(fakeRepo.products)));

      final updatedProduct = fakeRepo.products.first.copyWith(
        title: 'Updated Product Name Test',
      );

      final expectedStates = [
        isA<SellerCatalogSubmitting>(),
        isA<SellerCatalogActionSuccess>().having((s) => s.affectedProduct.title, 'title', 'Updated Product Name Test'),
        isA<SellerCatalogLoaded>().having((s) => s.products.first.title, 'firstTitle', 'Updated Product Name Test'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(UpdateProductListingEvent(updatedProduct));
    });

    test('Error during fetch emits SellerCatalogError with fallback items', () async {
      fakeRepo.shouldThrow = true;

      final expectedStates = [
        isA<SellerCatalogLoading>(),
        isA<SellerCatalogError>().having((s) => s.message, 'message', contains('Network error')),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const FetchSellerProductsEvent());
    });
  });
}
