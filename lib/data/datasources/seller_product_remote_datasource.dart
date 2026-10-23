import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

abstract class SellerProductRemoteDataSource {
  Future<List<dynamic>> getSellerProducts({int page = 0, int size = 20});
  Future<Map<String, dynamic>> submitProductListing(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> updateProductListing(String productId, Map<String, dynamic> payload);
  Future<List<String>> uploadProductImages(String productId, List<String> filePaths);
}

class SellerProductRemoteDataSourceImpl implements SellerProductRemoteDataSource {
  final ApiClient _client;

  SellerProductRemoteDataSourceImpl(this._client);

  @override
  Future<List<dynamic>> getSellerProducts({int page = 0, int size = 20}) async {
    final response = await _client.get(
      '${ApiEndpoints.sellerProducts}?page=$page&size=$size',
      requiresAuth: true,
    );
    if (response is Map && response['data'] is Map && response['data']['content'] is List) {
      return response['data']['content'] as List<dynamic>;
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> submitProductListing(Map<String, dynamic> payload) async {
    final response = await _client.post(
      ApiEndpoints.sellerProducts,
      body: payload,
      requiresAuth: true,
    );
    if (response is Map && response['data'] is Map) {
      return response['data'] as Map<String, dynamic>;
    }
    return response is Map<String, dynamic> ? response : {};
  }

  @override
  Future<Map<String, dynamic>> updateProductListing(String productId, Map<String, dynamic> payload) async {
    final response = await _client.put(
      ApiEndpoints.sellerProductById(productId),
      body: payload,
      requiresAuth: true,
    );
    if (response is Map && response['data'] is Map) {
      return response['data'] as Map<String, dynamic>;
    }
    return response is Map<String, dynamic> ? response : {};
  }

  @override
  Future<List<String>> uploadProductImages(String productId, List<String> filePaths) async {
    // Multi-part image upload hook
    return [];
  }
}
