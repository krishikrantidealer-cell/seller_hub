import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seller_hub/core/models/category.dart';
import 'package:seller_hub/data/datasources/category_local_datasource.dart';
import 'package:seller_hub/data/datasources/category_remote_datasource.dart';
import 'package:seller_hub/data/repositories/category_repository_impl.dart';
import 'package:seller_hub/domain/repositories/category_repository.dart';
import 'package:seller_hub/logic/category/category_bloc.dart';
import 'package:seller_hub/logic/category/category_event.dart';
import 'package:seller_hub/logic/category/category_state.dart';

class MockCategoryRemoteDataSource implements CategoryRemoteDataSource {
  bool shouldThrow = false;
  String errorMessage = 'Failed to load categories';

  final List<CategoryItem> mockData = const [
    CategoryItem(
      id: 'cat_root_1',
      name: 'Crop Protection',
      slug: 'crop-protection',
      parentId: null,
      level: 0,
      sortOrder: 0,
      isActive: true,
    ),
    CategoryItem(
      id: 'cat_sub_1',
      name: 'Bio Pesticides',
      slug: 'bio-pesticides',
      parentId: 'cat_root_1',
      level: 1,
      sortOrder: 0,
      isActive: true,
    ),
    CategoryItem(
      id: 'cat_leaf_1',
      name: 'Bio Insecticide',
      slug: 'bio-insecticide',
      parentId: 'cat_sub_1',
      level: 2,
      sortOrder: 0,
      isActive: true,
    ),
    CategoryItem(
      id: 'cat_root_2',
      name: 'Seeds',
      slug: 'seeds',
      parentId: null,
      level: 0,
      sortOrder: 1,
      isActive: true,
    ),
  ];

  @override
  Future<List<CategoryItem>> getCategories({int? level, String? parentId}) async {
    if (shouldThrow) {
      throw Exception(errorMessage);
    }
    return mockData.where((c) {
      if (level != null && c.level != level) return false;
      if (parentId != null && c.parentId != parentId) return false;
      return true;
    }).toList();
  }

  @override
  Future<CategoryItem> getCategoryById(String id) async {
    return mockData.firstWhere((c) => c.id == id);
  }

  @override
  Future<CategoryItem> createCategory({
    required String name,
    required String slug,
    String? parentId,
    int? sortOrder,
    String? iconUrl,
    bool isActive = true,
  }) async {
    return CategoryItem(
      id: 'new_cat',
      name: name,
      slug: slug,
      parentId: parentId,
      level: parentId != null ? 1 : 0,
      sortOrder: sortOrder ?? 0,
      iconUrl: iconUrl,
      isActive: isActive,
    );
  }

  @override
  Future<CategoryItem> updateCategory({
    required String id,
    required String name,
    required String slug,
    String? parentId,
    int? sortOrder,
    String? iconUrl,
    bool isActive = true,
  }) async {
    return CategoryItem(
      id: id,
      name: name,
      slug: slug,
      parentId: parentId,
      level: parentId != null ? 1 : 0,
      sortOrder: sortOrder ?? 0,
      iconUrl: iconUrl,
      isActive: isActive,
    );
  }

  @override
  Future<CategoryItem> deactivateCategory(String id) async {
    return CategoryItem(
      id: id,
      name: 'Deactivated',
      slug: 'deactivated',
      isActive: false,
    );
  }

  @override
  Future<CategoryItem> uploadCategoryImage({
    required String categoryId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    return CategoryItem(
      id: categoryId,
      name: 'With Image',
      slug: 'with-image',
      categoryImageUrl: 'https://storage.googleapis.com/test-bucket/Categories/$categoryId/images/$fileName',
      isActive: true,
    );
  }

  @override
  Future<CategoryItem> deleteCategoryImage(String categoryId) async {
    return CategoryItem(
      id: categoryId,
      name: 'Without Image',
      slug: 'without-image',
      categoryImageUrl: null,
      isActive: true,
    );
  }
}

void main() {
  group('CategoryBloc & 3-Tier Hierarchy Tests', () {
    late CategoryBloc categoryBloc;
    late CategoryRepository repository;
    late MockCategoryRemoteDataSource remoteDataSource;
    late CategoryLocalDataSource localDataSource;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      localDataSource = CategoryLocalDataSourceImpl(prefs);
      remoteDataSource = MockCategoryRemoteDataSource();
      repository = CategoryRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
      categoryBloc = CategoryBloc(categoryRepository: repository);
    });

    tearDown(() {
      categoryBloc.close();
    });

    test('Initial state has CategoryStatus.initial and empty categories', () {
      expect(categoryBloc.state.status, CategoryStatus.initial);
      expect(categoryBloc.state.allCategories, isEmpty);
      expect(categoryBloc.state.totalCount, 0);
    });

    test('InitializeCategories hydrates from local cache immediately with 0ms loading', () async {
      const cachedItem = CategoryItem(
        id: 'cached_root',
        name: 'Cached Protection',
        slug: 'cached-protection',
        parentId: null,
        level: 0,
        sortOrder: 0,
      );
      await localDataSource.cacheCategories(const [cachedItem]);

      categoryBloc.add(const InitializeCategories());

      await expectLater(
        categoryBloc.stream,
        emitsThrough(
          predicate<CategoryState>((s) =>
              s.status == CategoryStatus.loaded &&
              s.allCategories.isNotEmpty &&
              s.allCategories.first.name == 'Cached Protection'),
        ),
      );
    });

    test('FetchCategories correctly builds 3-level category hierarchy', () async {
      categoryBloc.add(const FetchCategories());
      await pumpEventQueue();

      expect(categoryBloc.state.status, CategoryStatus.loaded);
      expect(categoryBloc.state.allCategories.length, 4);
      expect(categoryBloc.state.rootCount, 2);
      expect(categoryBloc.state.subCount, 1);
      expect(categoryBloc.state.leafCount, 1);

      // Verify Level 0 -> Level 1 -> Level 2 nesting
      final rootProtection = categoryBloc.state.rootCategories.firstWhere((r) => r.id == 'cat_root_1');
      expect(rootProtection.name, 'Crop Protection');
      expect(rootProtection.children.length, 1);

      final subPesticides = rootProtection.children.first;
      expect(subPesticides.name, 'Bio Pesticides');
      expect(subPesticides.level, 1);
      expect(subPesticides.children.length, 1);

      final leafInsecticide = subPesticides.children.first;
      expect(leafInsecticide.name, 'Bio Insecticide');
      expect(leafInsecticide.level, 2);
    });

    test('FilterCategories filters and auto-expands parent hierarchy', () async {
      categoryBloc.add(const FetchCategories());
      await pumpEventQueue();

      // Search for leaf node "Insecticide"
      categoryBloc.add(const FilterCategories('Insecticide'));
      await pumpEventQueue();

      // Verify search query applied and ancestors auto-expanded
      expect(categoryBloc.state.searchQuery, 'Insecticide');
      expect(categoryBloc.state.expandedCategoryIds.contains('cat_root_1'), isTrue);
      expect(categoryBloc.state.expandedCategoryIds.contains('cat_sub_1'), isTrue);
    });

    test('SelectLevelFilter restricts tree to specific level', () async {
      categoryBloc.add(const FetchCategories());
      await pumpEventQueue();

      // Filter to Level 2 (Leaf nodes)
      categoryBloc.add(const SelectLevelFilter(2));
      await pumpEventQueue();

      expect(categoryBloc.state.selectedLevelFilter, 2);
      final filtered = categoryBloc.state.filteredTree;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Bio Insecticide');
      expect(filtered.first.level, 2);
    });

    test('ExpandAllCategories and CollapseAllCategories manage expansion set', () async {
      categoryBloc.add(const FetchCategories());
      await pumpEventQueue();

      categoryBloc.add(const ExpandAllCategories());
      await pumpEventQueue();
      expect(categoryBloc.state.expandedCategoryIds, isNotEmpty);

      categoryBloc.add(const CollapseAllCategories());
      await pumpEventQueue();
      expect(categoryBloc.state.expandedCategoryIds, isEmpty);
    });

    test('CategoryItem correctly parses MongoDB document with iconUrl emoji and displayOrder', () {
      final json = {
        '_id': '6ab4f6f619ec643fd9bf362d',
        'name': 'Fertilizers',
        'slug': 'fertilizers',
        'level': 0,
        'parentId': null,
        'iconUrl': '🌾',
        'displayOrder': 3,
        'isActive': true,
        'createdAt': '2026-09-24T10:09:58.334Z',
        'updatedAt': '2026-10-21T10:01:51.905Z',
      };

      final cat = CategoryItem.fromJson(json);

      expect(cat.id, '6ab4f6f619ec643fd9bf362d');
      expect(cat.name, 'Fertilizers');
      expect(cat.slug, 'fertilizers');
      expect(cat.level, 0);
      expect(cat.iconUrl, '🌾');
      expect(cat.effectiveIcon, '🌾');
      expect(cat.hasIcon, isTrue);
      expect(cat.isEmojiIcon, isTrue);
      expect(cat.sortOrder, 3);
      expect(cat.displayOrder, 3);
      expect(cat.isActive, isTrue);

      final serialized = cat.toJson();
      expect(serialized['iconUrl'], '🌾');
      expect(serialized['displayOrder'], 3);
    });

    test('UploadCategoryItemImage updates categoryImageUrl in state', () async {
      categoryBloc.add(const FetchCategories());
      await pumpEventQueue();

      categoryBloc.add(const UploadCategoryItemImage(
        categoryId: 'cat_root_1',
        fileBytes: [1, 2, 3],
        fileName: 'fertilizers.png',
      ));
      await pumpEventQueue();

      final updated = categoryBloc.state.categoryById['cat_root_1'];
      expect(updated, isNotNull);
      expect(updated!.categoryImageUrl, contains('fertilizers.png'));
      expect(updated.effectiveIcon, contains('fertilizers.png'));
    });

    test('DeleteCategoryItemImage clears categoryImageUrl in state', () async {
      categoryBloc.add(const FetchCategories());
      await pumpEventQueue();

      categoryBloc.add(const DeleteCategoryItemImage('cat_root_1'));
      await pumpEventQueue();

      final updated = categoryBloc.state.categoryById['cat_root_1'];
      expect(updated, isNotNull);
      expect(updated!.categoryImageUrl, isNull);
    });
  });
}
