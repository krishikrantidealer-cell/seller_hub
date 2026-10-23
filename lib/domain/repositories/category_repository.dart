class SellerCategory {
  final String id;
  final String name;
  final String slug;
  final String? parentId;

  const SellerCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
  });
}

abstract class CategoryRepository {
  Future<List<SellerCategory>> getRootCategories();
  Future<List<SellerCategory>> getCategoryChildren(String parentId);
}
