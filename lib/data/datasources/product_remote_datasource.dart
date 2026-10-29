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
  Future<void> deleteProductPermanently(String productId);
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

  static final Map<String, dynamic> _cachedPublicProductImages = {};
  static DateTime? _lastPublicImagesFetch;

  Future<void> _ensurePublicProductImagesCached() async {
    final now = DateTime.now();
    if (_cachedPublicProductImages.isNotEmpty &&
        _lastPublicImagesFetch != null &&
        now.difference(_lastPublicImagesFetch!).inMinutes < 10) {
      return;
    }
    try {
      final pubResp = await _apiClient.get(
        ApiEndpoints.products,
        queryParameters: {'page': 0, 'size': 100},
        requiresAuth: false,
      );
      if (pubResp['data'] != null && pubResp['data']['content'] is List) {
        final list = pubResp['data']['content'] as List;
        for (final p in list) {
          if (p is Map) {
            final id = p['id']?.toString();
            final code = p['productCode']?.toString();
            final imgs = p['productImages'];
            if (id != null && imgs != null) _cachedPublicProductImages[id] = imgs;
            if (code != null && imgs != null) _cachedPublicProductImages[code] = imgs;
            if (p['images'] != null && (p['images'] as List).isNotEmpty) {
              if (id != null) _cachedPublicProductImages['${id}_images'] = p['images'];
              if (code != null) _cachedPublicProductImages['${code}_images'] = p['images'];
            }
          }
        }
        _lastPublicImagesFetch = now;
      }
    } catch (_) {
      // Background enrichment fallback silently ignored
    }
  }

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
          requiresAuth: true,
        );
      } else {
        rethrow;
      }
    }

    // Enrich admin products with signed productImages from public catalog if images list is empty
    await _ensurePublicProductImagesCached();
    if (response['data'] != null && response['data']['content'] is List) {
      final content = response['data']['content'] as List;
      for (final item in content) {
        if (item is Map<String, dynamic>) {
          final id = item['id']?.toString() ?? '';
          final code = item['productCode']?.toString() ?? '';
          if (item['productImages'] == null || (item['productImages'] as List).isEmpty) {
            final cached = _cachedPublicProductImages[id] ?? _cachedPublicProductImages[code];
            if (cached != null) {
              item['productImages'] = cached;
            }
          }
          if (item['images'] == null || (item['images'] as List).isEmpty) {
            final cachedImgs = _cachedPublicProductImages['${id}_images'] ?? _cachedPublicProductImages['${code}_images'];
            if (cachedImgs != null) {
              item['images'] = cachedImgs;
            }
          }
        }
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
  Future<void> deleteProductPermanently(String productId) async {
    try {
      await _apiClient.delete(
        ApiEndpoints.adminProductPermanent(productId),
        requiresAuth: true,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // Backend requires soft-delete before permanently deleting
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
