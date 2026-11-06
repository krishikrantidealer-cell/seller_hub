import '../../core/models/collection.dart';
import '../../domain/repositories/collection_repository.dart';
import '../datasources/collection_local_datasource.dart';
import '../datasources/collection_remote_datasource.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final CollectionRemoteDataSource remoteDataSource;
  final CollectionLocalDataSource? localDataSource;

  CollectionRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
  });

  @override
  Future<CollectionsData> getCollections() async {
    final data = await remoteDataSource.getCollections();
    // Asynchronously update local cache so next restarts load with 0ms delay
    localDataSource?.cacheCollections(data);
    return data;
  }

  @override
  Future<CollectionsData?> getCachedCollections() async {
    return localDataSource?.getCachedCollections();
  }

  @override
  Future<void> updateLocalCollection(CollectionItem collection) async {
    await localDataSource?.updateCachedCollection(collection);
  }

  @override
  Future<CollectionItem> createCollection({
    required String name,
    required String slug,
    required String description,
    String? image,
    bool isActive = true,
    int priority = 0,
    List<Map<String, dynamic>> subCollections = const [],
    String? bannerTitle,
  }) async {
    final newItem = await remoteDataSource.createCollection(
      name: name,
      slug: slug,
      description: description,
      image: image,
      isActive: isActive,
      priority: priority,
      subCollections: subCollections,
      bannerTitle: bannerTitle,
    );
    await localDataSource?.updateCachedCollection(newItem);
    return newItem;
  }

  @override
  Future<CollectionItem> updateCollection({
    required String id,
    required CollectionItem collection,
  }) async {
    final updatedItem = await remoteDataSource.updateCollection(
      id: id,
      collection: collection,
    );
    await localDataSource?.updateCachedCollection(updatedItem);
    return updatedItem;
  }

  @override
  Future<CollectionItem> deactivateCollection(String id) async {
    final deactivatedItem = await remoteDataSource.deactivateCollection(id);
    await localDataSource?.updateCachedCollection(deactivatedItem);
    return deactivatedItem;
  }

  @override
  Future<CollectionItem> activateCollection(String id) async {
    final activatedItem = await remoteDataSource.activateCollection(id);
    await localDataSource?.updateCachedCollection(activatedItem);
    return activatedItem;
  }

  @override
  Future<void> deleteCollectionPermanently(String id) async {
    await remoteDataSource.deleteCollectionPermanently(id);
    await localDataSource?.removeCachedCollection(id);
  }

  @override
  Future<List<String>> deleteCollectionsPermanently(List<String> ids) async {
    final deleted = await remoteDataSource.deleteCollectionsPermanently(ids);
    for (final id in deleted) {
      await localDataSource?.removeCachedCollection(id);
    }
    return deleted;
  }

  @override
  Future<CollectionItem> addSubCollection({
    required String collectionId,
    required String name,
    required String slug,
    String? image,
    bool isActive = true,
  }) async {
    final updatedCollection = await remoteDataSource.addSubCollection(
      collectionId: collectionId,
      name: name,
      slug: slug,
      image: image,
      isActive: isActive,
    );
    await updateLocalCollection(updatedCollection);
    return updatedCollection;
  }

  @override
  Future<List<String>> deleteSubCollection({
    required String collectionId,
    required String subCollectionId,
  }) async {
    final deletedIds = await remoteDataSource.deleteSubCollection(
      collectionId: collectionId,
      subCollectionId: subCollectionId,
    );
    // Refresh cached collection if present
    final cached = await localDataSource?.getCachedCollections();
    if (cached != null) {
      final items = List<CollectionItem>.from(cached.items);
      final idx = items.indexWhere((c) => c.id == collectionId);
      if (idx != -1) {
        final col = items[idx];
        final updatedSubs = col.subCollections
            .where((s) => !deletedIds.contains(s.id))
            .toList();
        items[idx] = col.copyWith(
          subCollections: updatedSubs,
          subCollectionCount: updatedSubs.length,
        );
        await localDataSource?.cacheCollections(CollectionsData(
          count: items.length,
          items: items,
        ));
      }
    }
    return deletedIds;
  }

  @override
  Future<List<String>> deleteSubCollectionsBulk({
    required String collectionId,
    required List<String> subCollectionIds,
  }) async {
    final deletedIds = await remoteDataSource.deleteSubCollectionsBulk(
      collectionId: collectionId,
      subCollectionIds: subCollectionIds,
    );
    final cached = await localDataSource?.getCachedCollections();
    if (cached != null) {
      final items = List<CollectionItem>.from(cached.items);
      final idx = items.indexWhere((c) => c.id == collectionId);
      if (idx != -1) {
        final col = items[idx];
        final updatedSubs = col.subCollections
            .where((s) => !deletedIds.contains(s.id))
            .toList();
        items[idx] = col.copyWith(
          subCollections: updatedSubs,
          subCollectionCount: updatedSubs.length,
        );
        await localDataSource?.cacheCollections(CollectionsData(
          count: items.length,
          items: items,
        ));
      }
    }
    return deletedIds;
  }

  @override
  Future<String> uploadCollectionImageDirect({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    return await remoteDataSource.uploadCollectionImageDirect(
      fileBytes: fileBytes,
      fileName: fileName,
    );
  }

  @override
  Future<CollectionItem> uploadCollectionImage({
    required String collectionId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final updated = await remoteDataSource.uploadCollectionImage(
      collectionId: collectionId,
      fileBytes: fileBytes,
      fileName: fileName,
    );
    await localDataSource?.updateCachedCollection(updated);
    return updated;
  }

  @override
  Future<CollectionItem> uploadSubCollectionImage({
    required String collectionId,
    required String subCollectionId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final updated = await remoteDataSource.uploadSubCollectionImage(
      collectionId: collectionId,
      subCollectionId: subCollectionId,
      fileBytes: fileBytes,
      fileName: fileName,
    );
    await localDataSource?.updateCachedCollection(updated);
    return updated;
  }
}
