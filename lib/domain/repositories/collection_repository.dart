import '../../core/models/collection.dart';

abstract class CollectionRepository {
  /// Retrieve collections from server and update local cache
  Future<CollectionsData> getCollections();

  /// Retrieve locally cached collections (0ms instant startup)
  Future<CollectionsData?> getCachedCollections();

  /// Update collection in local persistent cache
  Future<void> updateLocalCollection(CollectionItem collection);
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
