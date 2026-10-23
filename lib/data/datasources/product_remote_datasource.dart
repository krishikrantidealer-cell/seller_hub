import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/api/product_response_dto.dart';

abstract class ProductRemoteDataSource {
  Future<ProductResponseDto> getProducts({
    int page = 0,
    int size = 20,
  });
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient _apiClient;

  ProductRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ProductResponseDto> getProducts({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.products,
      queryParameters: {
        'page': page,
        'size': size,
      },
      requiresAuth: true,
    );

    final dto = ProductResponseDto.fromJson(response);
    if (!dto.success || dto.data == null) {
      throw ApiException(
        message: dto.message.isNotEmpty ? dto.message : 'Failed to retrieve products',
        details: response,
      );
    }

    return dto;
  }
}
