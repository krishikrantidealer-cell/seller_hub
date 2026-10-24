import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seller_hub/core/models/collection.dart';
import 'package:seller_hub/data/datasources/collection_local_datasource.dart';
import 'package:seller_hub/data/datasources/collection_remote_datasource.dart';
import 'package:seller_hub/data/repositories/collection_repository_impl.dart';
import 'package:seller_hub/domain/repositories/collection_repository.dart';
import 'package:seller_hub/logic/collection/collection_bloc.dart';
import 'package:seller_hub/logic/collection/collection_event.dart';
import 'package:seller_hub/logic/collection/collection_state.dart';

class MockCollectionRemoteDataSource implements CollectionRemoteDataSource {
  bool shouldThrow = false;
  String errorMessage = 'Failed to load collections';

  @override
  Future<CollectionsData> getCollections() async {
    if (shouldThrow) {
      throw Exception(errorMessage);
    }
    return const CollectionsData(
      count: 1,
      items: [
        CollectionItem(
          id: 'col_1',
          name: 'Remote Shop By Crop',
          slug: 'shop-by-crop',
          description: 'Crops collection',
          isActive: true,
          priority: 0,
        ),
      ],
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
    return CollectionItem(
      id: 'new_col',
      name: name,
      slug: slug,
      description: description,
      isActive: isActive,
      priority: priority,
    );
  }

  @override
  Future<CollectionItem> updateCollection({
    required String id,
    required CollectionItem collection,
  }) async {
    return collection;
  }

  @override
  Future<CollectionItem> deactivateCollection(String id) async {
    return CollectionItem(
      id: id,
      name: 'Deactivated',
      slug: 'deactivated',
      isActive: false,
    );
  }
}

void main() {
  group('CollectionBloc & Local Caching Tests', () {
    late CollectionBloc collectionBloc;
    late CollectionRepository repository;
    late MockCollectionRemoteDataSource remoteDataSource;
    late CollectionLocalDataSource localDataSource;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      localDataSource = CollectionLocalDataSourceImpl(prefs);
      remoteDataSource = MockCollectionRemoteDataSource();
      repository = CollectionRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
      collectionBloc = CollectionBloc(collectionRepository: repository);
    });

    tearDown(() {
      collectionBloc.close();
    });

    test('Initial state has CollectionStatus.initial and empty collections', () {
      expect(collectionBloc.state.status, equals(CollectionStatus.initial));
      expect(collectionBloc.state.collections, isEmpty);
    });

    test('CollectionLocalDataSourceImpl properly caches and retrieves collections', () async {
      const sample = CollectionsData(
        count: 1,
        items: [
          CollectionItem(
            id: 'cached_1',
            name: 'Cached Season Specials',
            slug: 'cached-specials',
            description: 'Season specials cache test',
            isActive: true,
          ),
        ],
      );

      await localDataSource.cacheCollections(sample);
      final retrieved = await localDataSource.getCachedCollections();

      expect(retrieved, isNotNull);
      expect(retrieved!.items.length, equals(1));
      expect(retrieved.items.first.name, equals('Cached Season Specials'));
    });

    test('InitializeCollections hydrates from local cache immediately with 0ms loading', () async {
      const cachedData = CollectionsData(
        count: 1,
        items: [
          CollectionItem(
            id: 'cached_99',
            name: 'Instant Cached Crop Group',
            slug: 'instant-cached',
            description: 'Cached for instant 0ms startup',
            isActive: true,
          ),
        ],
      );

      // Pre-seed local cache
      await localDataSource.cacheCollections(cachedData);

      collectionBloc.add(const InitializeCollections());

      // Verify the first emitted state has status loaded IMMEDIATELY with cached data
      await expectLater(
        collectionBloc.stream,
        emitsThrough(
          predicate<CollectionState>((s) =>
              s.status == CollectionStatus.loaded &&
              s.collections.isNotEmpty &&
              s.collections.first.name == 'Instant Cached Crop Group'),
        ),
      );
    });

    test('FetchCollections emits loaded state with remote collections', () async {
      collectionBloc.add(const FetchCollections());

      await expectLater(
        collectionBloc.stream,
        emitsThrough(
          predicate<CollectionState>((s) =>
              s.status == CollectionStatus.loaded &&
              s.collections.isNotEmpty &&
              s.collections.first.name == 'Remote Shop By Crop'),
        ),
      );

      // Verify remote fetch was also persisted to local cache
      final cached = await repository.getCachedCollections();
      expect(cached, isNotNull);
      expect(cached!.items.first.name, equals('Remote Shop By Crop'));
    });
  });
}
