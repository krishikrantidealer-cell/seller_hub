import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

abstract class SellerOrderRemoteDataSource {
  Future<List<dynamic>> getSellerOrders({int page = 0, int size = 20});
  Future<Map<String, dynamic>> getSellerOrderById(String orderId);
}

class SellerOrderRemoteDataSourceImpl implements SellerOrderRemoteDataSource {
  final ApiClient _client;

  SellerOrderRemoteDataSourceImpl(this._client);

  @override
  Future<List<dynamic>> getSellerOrders({int page = 0, int size = 20}) async {
    final response = await _client.get(
      '${ApiEndpoints.sellerOrders}?page=$page&size=$size',
      requiresAuth: true,
    );
    if (response is Map && response['data'] is Map && response['data']['content'] is List) {
      return response['data']['content'] as List<dynamic>;
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> getSellerOrderById(String orderId) async {
    final response = await _client.get(
      ApiEndpoints.sellerOrderById(orderId),
      requiresAuth: true,
    );
    if (response is Map && response['data'] is Map) {
      return response['data'] as Map<String, dynamic>;
    }
    return {};
  }
}
