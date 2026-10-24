import '../../core/models/collection.dart';
import '../../domain/repositories/collection_repository.dart';
import '../datasources/collection_remote_datasource.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final CollectionRemoteDataSource remoteDataSource;

  CollectionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<CollectionsData> getCollections() async {
    return await remoteDataSource.getCollections();
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
    return await remoteDataSource.createCollection(
      name: name,
      slug: slug,
      description: description,
      isActive: isActive,
      priority: priority,
      subCollections: subCollections,
      bannerTitle: bannerTitle,
    );
  }

  @override
  Future<CollectionItem> updateCollection({
    required String id,
    required CollectionItem collection,
  }) async {
    return await remoteDataSource.updateCollection(
      id: id,
      collection: collection,
    );
  }
}
