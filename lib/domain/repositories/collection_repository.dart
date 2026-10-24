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
}
