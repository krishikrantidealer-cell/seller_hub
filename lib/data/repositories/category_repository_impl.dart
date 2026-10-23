import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _remoteDataSource;

  CategoryRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<SellerCategory>> getRootCategories() async {
    try {
      final list = await _remoteDataSource.getRootCategories();
      if (list.isNotEmpty) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(
              (json) => SellerCategory(
                id: json['id']?.toString() ?? '',
                name: json['name']?.toString() ?? '',
                slug: json['slug']?.toString() ?? '',
                parentId: json['parentId']?.toString(),
              ),
            )
            .toList();
      }
    } catch (_) {}

    return const [
      SellerCategory(id: 'crop-protection', name: 'Crop Protection', slug: 'crop-protection'),
      SellerCategory(id: 'fertilizers', name: 'Fertilizers', slug: 'fertilizers'),
      SellerCategory(id: 'seeds', name: 'Seeds', slug: 'seeds'),
      SellerCategory(id: 'equipments', name: 'Equipments', slug: 'equipments'),
      SellerCategory(id: 'irrigation', name: 'Irrigation', slug: 'irrigation'),
      SellerCategory(id: 'gardening', name: 'Gardening', slug: 'gardening'),
      SellerCategory(id: 'organic-farming', name: 'Organic Farming', slug: 'organic-farming'),
      SellerCategory(id: 'insecticides', name: 'Insecticides', slug: 'insecticides'),
    ];
  }

  @override
  Future<List<SellerCategory>> getCategoryChildren(String parentId) async {
    try {
      final list = await _remoteDataSource.getCategoryChildren(parentId);
      if (list.isNotEmpty) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(
              (json) => SellerCategory(
                id: json['id']?.toString() ?? '',
                name: json['name']?.toString() ?? '',
                slug: json['slug']?.toString() ?? '',
                parentId: json['parentId']?.toString(),
              ),
            )
            .toList();
      }
    } catch (_) {}

    return [];
  }
}
