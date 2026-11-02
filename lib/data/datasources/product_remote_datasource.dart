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
  Future<Product> createProduct(Map<String, dynamic> productPayload);
  Future<Product> updateProduct(String productId, Map<String, dynamic> productPayload);
  Future<void> deleteProductPermanently(String productId);
  Future<void> deleteMultipleProductsPermanently(List<String> productIds);
  Future<Product> updateProductAvailability(String productId, bool available);
  Future<Product> uploadProductImages(
    String productId,
    List<List<int>> filesBytes,
    List<String> fileNames,
  );
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient _apiClient;

  ProductRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ProductResponseDto> getProducts({
    int page = 0,
    int size = 20,
  }) async {
    Map<String, dynamic> response;
    try {
      response = await _apiClient.get(
        ApiEndpoints.adminProducts,
        queryParameters: {
          'status': 'ALL',
          'page': page,
          'size': size,
        },
        requiresAuth: true,
      );
    } on ApiException catch (e) {
      // Fallback to public catalog if admin endpoint encounters permission or route issues
      if (e.statusCode == 401 || e.statusCode == 403 || e.statusCode == 404) {
        response = await _apiClient.get(
          ApiEndpoints.products,
          queryParameters: {
            'page': page,
            'size': size,
          },
          requiresAuth: false,
        );
      } else {
        rethrow;
      }
    }

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
      response = await _apiClient.put(path, body: body, requiresAuth: true);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405 || e.statusCode == 500) {
        try {
          response = await _apiClient.patch(path, body: body, requiresAuth: true);
        } on ApiException catch (patchErr) {
          if (patchErr.statusCode == 404 || patchErr.statusCode == 405 || patchErr.statusCode == 500) {
            response = await _apiClient.post(path, body: body, requiresAuth: true);
          } else {
            rethrow;
          }
        }
      } else {
        rethrow;
      }
    }

    final rawData = response['data'] ?? response;
    if (rawData is Map) {
      return Product.fromJson(Map<String, dynamic>.from(rawData));
    }

    throw const ApiException(
      message: 'Unexpected product collections response format from server.',
    );
  }

  @override
  Future<Product> createProduct(Map<String, dynamic> productPayload) async {
    final response = await _apiClient.post(
      ApiEndpoints.adminProducts,
      body: productPayload,
      requiresAuth: true,
    );

    final rawData = response['data'] ?? response;
    if (rawData is Map) {
      return Product.fromJson(Map<String, dynamic>.from(rawData));
    }

    throw const ApiException(
      message: 'Unexpected product creation response format from server.',
    );
  }

  @override
  Future<Product> updateProduct(String productId, Map<String, dynamic> productPayload) async {
    final response = await _apiClient.patch(
      ApiEndpoints.adminProduct(productId),
      body: productPayload,
      requiresAuth: true,
    );

    final rawData = response['data'] ?? response;
    if (rawData is Map) {
      return Product.fromJson(Map<String, dynamic>.from(rawData));
    }

    throw const ApiException(
      message: 'Unexpected product update response format from server.',
    );
  }

  @override
  Future<void> deleteMultipleProductsPermanently(List<String> productIds) async {
    if (productIds.isEmpty) return;
    try {
      await _apiClient.delete(
        ApiEndpoints.adminProductsPermanent,
        body: {'productIds': productIds},
        requiresAuth: true,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        // Fallback to legacy single-endpoint delete
        for (final id in productIds) {
          await _deleteSingleLegacy(id);
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> deleteProductPermanently(String productId) async {
    await deleteMultipleProductsPermanently([productId]);
  }

  Future<void> _deleteSingleLegacy(String productId) async {
    try {
      await _apiClient.delete(
        ApiEndpoints.adminProductPermanent(productId),
        requiresAuth: true,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        await _apiClient.delete(
          ApiEndpoints.adminProduct(productId),
          requiresAuth: true,
        );
        await _apiClient.delete(
          ApiEndpoints.adminProductPermanent(productId),
          requiresAuth: true,
        );
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<Product> updateProductAvailability(String productId, bool available) async {
    Map<String, dynamic> response;
    try {
      response = await _apiClient.patch(
        ApiEndpoints.adminProductAvailability(productId),
        body: {'available': available},
        requiresAuth: true,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 409 && available) {
        try {
          await _apiClient.patch(
            ApiEndpoints.adminProductReview(productId),
            body: {'approved': true},
            requiresAuth: true,
          );
          response = await _apiClient.patch(
            ApiEndpoints.adminProductAvailability(productId),
            body: {'available': available},
            requiresAuth: true,
          );
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    final rawData = response['data'] ?? response;
    if (rawData is Map) {
      return Product.fromJson(Map<String, dynamic>.from(rawData));
    }
    throw const ApiException(
      message: 'Unexpected product availability response format from server.',
    );
  }

  @override
  Future<Product> uploadProductImages(
    String productId,
    List<List<int>> filesBytes,
    List<String> fileNames,
  ) async {
    await _apiClient.postMultipartFiles(
      ApiEndpoints.adminProductImages(productId),
      fileFieldName: 'files',
      filesBytes: filesBytes,
      fileNames: fileNames,
      requiresAuth: true,
    );

    // Fetch the updated product so all newly processed cloud images are populated
    final response = await _apiClient.get(
      ApiEndpoints.adminProduct(productId),
      requiresAuth: true,
    );
    final rawData = response['data'] ?? response;
    if (rawData is Map) {
      return Product.fromJson(Map<String, dynamic>.from(rawData));
    }
    throw const ApiException(
      message: 'Failed to retrieve updated product after image upload.',
    );
  }
}
