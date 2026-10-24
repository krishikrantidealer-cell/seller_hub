import '../../core/constants/api_endpoints.dart';
import '../../core/models/collection.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

abstract class CollectionRemoteDataSource {
  Future<CollectionsData> getCollections();
  Future<CollectionItem> createCollection({
    required String name,
    required String slug,
    required String description,
    bool isActive = true,
    int priority = 0,
    List<Map<String, dynamic>> subCollections = const [],
    String? bannerTitle,
  });
  Future<CollectionItem> updateCollection({
    required String id,
    required CollectionItem collection,
  });
  Future<CollectionItem> deactivateCollection(String id);
}

class CollectionRemoteDataSourceImpl implements CollectionRemoteDataSource {
  final ApiClient apiClient;

  CollectionRemoteDataSourceImpl(this.apiClient);

  @override
  Future<CollectionsData> getCollections() async {
    final response = await apiClient.get(
      ApiEndpoints.collections,
      requiresAuth: false,
    );

    final rawData = response['data'];
    if (rawData is Map<String, dynamic>) {
      return CollectionsData.fromJson(rawData);
    }

    throw const ApiException(
      message: 'Unexpected collection response format from server.',
    );
  }

  @override
  Future<CollectionItem> createCollection({
    required String name,
    required String slug,
    required String description,
    bool isActive = true,
    int priority = 0,
    List<Map<String, dynamic>> subCollections = const [],
    String? bannerTitle,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'slug': slug,
      'description': description,
      'isActive': isActive,
      'priority': priority,
      'subCollections': subCollections,
    };

    if (bannerTitle != null && bannerTitle.isNotEmpty) {
      body['bannerTitle'] = bannerTitle;
    }

    final response = await apiClient.post(
      ApiEndpoints.adminCollections,
      body: body,
      requiresAuth: true,
    );

    final rawData = response['data'];
    if (rawData is Map<String, dynamic>) {
      return CollectionItem.fromJson(rawData);
    }

    throw const ApiException(
      message: 'Unexpected create collection response format from server.',
    );
  }

  @override
  Future<CollectionItem> updateCollection({
    required String id,
    required CollectionItem collection,
  }) async {
    final response = await apiClient.put(
      '${ApiEndpoints.adminCollections}/$id',
      body: collection.toJson(),
      requiresAuth: true,
    );

    final rawData = response['data'] ?? response;
    if (rawData is Map<String, dynamic>) {
      return CollectionItem.fromJson(rawData);
    }

    throw const ApiException(
      message: 'Unexpected update collection response format from server.',
    );
  }

  @override
  Future<CollectionItem> deactivateCollection(String id) async {
    final path = '${ApiEndpoints.adminCollections}/$id';
    try {
      final response = await apiClient.delete(
        path,
        requiresAuth: true,
      );

      final rawData = response['data'] ?? response;
      if (rawData is Map<String, dynamic>) {
        return CollectionItem.fromJson(rawData);
      }

      throw const ApiException(
        message: 'Unexpected deactivate collection response format from server.',
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        final response = await apiClient.patch(
          path,
          body: {'isActive': false},
          requiresAuth: true,
        );
        final rawData = response['data'] ?? response;
        if (rawData is Map<String, dynamic>) {
          return CollectionItem.fromJson(rawData);
        }
      }
      rethrow;
    }
  }
}
