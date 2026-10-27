import '../../core/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../datasources/category_remote_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;
  final CategoryLocalDataSource? localDataSource;

  CategoryRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
  });

  @override
  Future<List<CategoryItem>> getCategories({
    bool forceRefresh = false,
    int? level,
    String? parentId,
  }) async {
    if (!forceRefresh && level == null && (parentId == null || parentId.isEmpty)) {
      final cached = await localDataSource?.getCachedCategories();
      if (cached != null && cached.isNotEmpty) {
        // Return cached and trigger silent sync
        _syncInBackground();
        return cached;
      }
    }

    final categories = await remoteDataSource.getCategories(level: level, parentId: parentId);
    if (level == null && (parentId == null || parentId.isEmpty)) {
      localDataSource?.cacheCategories(categories);
    }
    return categories;
  }

  void _syncInBackground() async {
    try {
      final fresh = await remoteDataSource.getCategories();
      localDataSource?.cacheCategories(fresh);
    } catch (_) {}
  }

  @override
  Future<List<CategoryItem>?> getCachedCategories() async {
    return localDataSource?.getCachedCategories();
  }

  @override
  Future<CategoryItem> getCategoryById(String id) {
    return remoteDataSource.getCategoryById(id);
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
    final created = await remoteDataSource.createCategory(
      name: name,
      slug: slug,
      parentId: parentId,
      sortOrder: sortOrder,
      iconUrl: iconUrl,
      isActive: isActive,
    );
    // Refresh cache
    _syncInBackground();
    return created;
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
    final updated = await remoteDataSource.updateCategory(
      id: id,
      name: name,
      slug: slug,
      parentId: parentId,
      sortOrder: sortOrder,
      iconUrl: iconUrl,
      isActive: isActive,
    );
    _syncInBackground();
    return updated;
  }

  @override
  Future<CategoryItem> deactivateCategory(String id) async {
    final deactivated = await remoteDataSource.deactivateCategory(id);
    _syncInBackground();
    return deactivated;
  }
}
