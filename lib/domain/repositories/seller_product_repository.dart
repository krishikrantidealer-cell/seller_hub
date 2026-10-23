import '../../core/models/product.dart';

abstract class SellerProductRepository {
  Future<List<Product>> getSellerProducts({int page = 0, int size = 20});
  Future<Product> submitProductListing(Product product);
  Future<Product> updateProductListing(Product product);
  Future<List<String>> uploadProductImages(String productId, List<String> filePaths);
}
