import '../../core/models/product.dart';

abstract class ProductRepository {
  /// Fetch paginated products from {{baseUrl}}/api/v1/products?page=...&size=...
  Future<ProductPageData> getProducts({
    int page = 0,
    int size = 20,
  });

  /// Fetch all catalog products across pages (bounded by backend MAX_SIZE 100 per request)
  Future<List<Product>> getAllProducts();

  /// Immediately retrieve locally cached products (0ms) on startup / restart
  Future<ProductPageData?> getCachedProducts({
    int page = 0,
    int size = 20,
  });

  /// Update cached product locally in persistent storage
  Future<void> updateLocalProduct(Product product);

  /// Assign storefront collections and sub-collections to a product
  Future<Product> assignCollections({
    required String productId,
    required List<String> collectionIds,
    required List<String> subCollectionIds,
  });

  /// Create / assign a product to a seller via POST /api/v1/admin/products
  Future<Product> createProduct(Product product);
}
