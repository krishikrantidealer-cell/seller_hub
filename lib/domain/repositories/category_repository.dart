import '../../core/models/category.dart';

abstract class CategoryRepository {
  /// Retrieves all categories, optionally filtering by level or parent.
  /// If forceRefresh is false, it uses local cache if available.
  Future<List<CategoryItem>> getCategories({
    bool forceRefresh = false,
    int? level,
    String? parentId,
  });

  /// Immediate local cache retrieval (0ms startup)
  Future<List<CategoryItem>?> getCachedCategories();

  /// Retrieves a single category by ID
  Future<CategoryItem> getCategoryById(String id);

  /// Creates a category
  Future<CategoryItem> createCategory({
    required String name,
    required String slug,
    String? parentId,
    int? sortOrder,
    String? iconUrl,
    bool isActive = true,
  });

  /// Updates a category
  Future<CategoryItem> updateCategory({
    required String id,
    required String name,
    required String slug,
    String? parentId,
    int? sortOrder,
    String? iconUrl,
    bool isActive = true,
  });

  /// Deactivates a category
  Future<CategoryItem> deactivateCategory(String id);
}
