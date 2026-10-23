import '../../core/models/product.dart';
import '../../domain/repositories/seller_product_repository.dart';
import '../datasources/seller_product_remote_datasource.dart';

class SellerProductRepositoryImpl implements SellerProductRepository {
  final SellerProductRemoteDataSource _remoteDataSource;

  SellerProductRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Product>> getSellerProducts({int page = 0, int size = 20}) async {
    try {
      final list = await _remoteDataSource.getSellerProducts(page: page, size: size);
      if (list.isNotEmpty) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((json) => Product.fromJson(json))
            .toList();
      }
    } catch (_) {}

    return List.from(Product.sampleProducts);
  }

  @override
  Future<Product> submitProductListing(Product product) async {
    try {
      final payload = product.toJson();
      final data = await _remoteDataSource.submitProductListing(payload);
      if (data.isNotEmpty) {
        return Product.fromJson(data);
      }
    } catch (_) {}

    return product;
  }

  @override
  Future<Product> updateProductListing(Product product) async {
    try {
      final payload = product.toJson();
      final data = await _remoteDataSource.updateProductListing(product.id, payload);
      if (data.isNotEmpty) {
        return Product.fromJson(data);
      }
    } catch (_) {}

    return product;
  }

  @override
  Future<List<String>> uploadProductImages(String productId, List<String> filePaths) async {
    try {
      return await _remoteDataSource.uploadProductImages(productId, filePaths);
    } catch (_) {
      return [];
    }
  }
}
