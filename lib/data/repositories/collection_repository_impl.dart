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
    bool isActive = true,
    int priority = 0,
    List<Map<String, dynamic>> subCollections = const [],
    String? bannerTitle,
  }) async {
    final newItem = await remoteDataSource.createCollection(
      name: name,
      slug: slug,
      description: description,
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
}
