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
  Future<CollectionItem> activateCollection(String id);
  Future<void> deleteCollectionPermanently(String id);
  Future<List<String>> deleteCollectionsPermanently(List<String> ids);
  Future<CollectionItem> addSubCollection({
    required String collectionId,
    required String name,
    required String slug,
    String? image,
    bool isActive = true,
  });
  Future<List<String>> deleteSubCollection({
    required String collectionId,
    required String subCollectionId,
  });
  Future<List<String>> deleteSubCollectionsBulk({
    required String collectionId,
    required List<String> subCollectionIds,
  });
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

  @override
  Future<CollectionItem> activateCollection(String id) async {
    final path = '${ApiEndpoints.adminCollections}/$id/activate';
    try {
      final response = await apiClient.post(
        path,
        body: {},
        requiresAuth: true,
      );
      final rawData = response['data'] ?? response;
      if (rawData is Map<String, dynamic>) {
        return CollectionItem.fromJson(rawData);
      }
      throw const ApiException(
        message: 'Unexpected activate collection response format from server.',
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        final response = await apiClient.patch(
          '${ApiEndpoints.adminCollections}/$id',
          body: {'isActive': true},
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

  @override
  Future<void> deleteCollectionPermanently(String id) async {
    final path = '${ApiEndpoints.adminCollections}/$id?permanent=true';
    await apiClient.delete(
      path,
      requiresAuth: true,
    );
  }

  @override
  Future<List<String>> deleteCollectionsPermanently(List<String> ids) async {
    final response = await apiClient.delete(
      ApiEndpoints.adminCollections,
      body: {'collectionIds': ids},
      requiresAuth: true,
    );
    final rawData = response['data'];
    if (rawData is Map<String, dynamic> && rawData['items'] is List) {
      return (rawData['items'] as List).map((e) => e.toString()).toList();
    }
    return ids;
  }

  @override
  Future<CollectionItem> addSubCollection({
    required String collectionId,
    required String name,
    required String slug,
    String? image,
    bool isActive = true,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'slug': slug,
      'isActive': isActive,
    };
    if (image != null && image.isNotEmpty) {
      body['image'] = image;
    }
    final response = await apiClient.post(
      '${ApiEndpoints.adminCollections}/$collectionId/subcollections',
      body: body,
      requiresAuth: true,
    );
    final rawData = response['data'];
    return CollectionItem.fromJson(rawData as Map<String, dynamic>);
  }

  @override
  Future<List<String>> deleteSubCollection({
    required String collectionId,
    required String subCollectionId,
  }) async {
    final path = '${ApiEndpoints.adminCollections}/$collectionId/subcollections/$subCollectionId';
    final response = await apiClient.delete(
      path,
      requiresAuth: true,
    );
    final rawData = response['data'];
    if (rawData is Map<String, dynamic> && rawData['items'] is List) {
      return (rawData['items'] as List).map((e) => e.toString()).toList();
    }
    return [subCollectionId];
  }

  @override
  Future<List<String>> deleteSubCollectionsBulk({
    required String collectionId,
    required List<String> subCollectionIds,
  }) async {
    final path = '${ApiEndpoints.adminCollections}/$collectionId/subcollections';
    final response = await apiClient.delete(
      path,
      body: {'subCollectionIds': subCollectionIds},
      requiresAuth: true,
    );
    final rawData = response['data'];
    if (rawData is Map<String, dynamic> && rawData['items'] is List) {
      return (rawData['items'] as List).map((e) => e.toString()).toList();
    }
    return subCollectionIds;
  }
}
