import '../../core/constants/api_endpoints.dart';
import '../../core/models/product.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/api/product_response_dto.dart';

abstract class ProductRemoteDataSource {
  Future<ProductResponseDto> getProducts({
    int page = 0,
    int size = 20,
  });
  Future<Product> assignCollections({
    required String productId,
    required List<String> collectionIds,
    required List<String> subCollectionIds,
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

  @override
  Future<Product> assignCollections({
    required String productId,
    required List<String> collectionIds,
    required List<String> subCollectionIds,
  }) async {
    final body = {
      'collectionIds': collectionIds,
      'subCollectionIds': subCollectionIds,
    };
    final path = ApiEndpoints.productCollections(productId);

    Map<String, dynamic> response;
    try {
      response = await _apiClient.post(path, body: body, requiresAuth: true);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        response = await _apiClient.put(path, body: body, requiresAuth: true);
      } else {
        rethrow;
      }
    }

    final rawData = response['data'] ?? response;
    if (rawData is Map<String, dynamic>) {
      return Product.fromJson(rawData);
    }

    throw const ApiException(
      message: 'Unexpected product collections response format from server.',
    );
  }
}
