import '../../core/models/product.dart';

abstract class ProductRepository {
  /// Fetch paginated products from {{baseUrl}}/api/v1/products?page=...&size=...
  Future<ProductPageData> getProducts({
    int page = 0,
    int size = 20,
  });

  /// Immediately retrieve locally cached products (0ms) on startup / restart
  Future<ProductPageData?> getCachedProducts({
    int page = 0,
    int size = 20,
  });

  /// Update cached product locally in persistent storage
  Future<void> updateLocalProduct(Product product);
}
