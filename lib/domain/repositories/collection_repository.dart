import '../../core/models/collection.dart';

abstract class CollectionRepository {
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
}
