import '../../core/constants/api_endpoints.dart';
import '../../core/models/category.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

abstract class CategoryRemoteDataSource {
  /// Fetches all categories across pages from {{baseUrl}}/api/v1/categories
  Future<List<CategoryItem>> getCategories({int? level, String? parentId});

  /// Fetches a single category by ID
  Future<CategoryItem> getCategoryById(String id);

  /// Creates a category via admin API
  Future<CategoryItem> createCategory({
    required String name,
    required String slug,
    String? parentId,
    int? sortOrder,
    String? iconUrl,
    bool isActive = true,
  });

  /// Updates a category via admin API
  Future<CategoryItem> updateCategory({
    required String id,
    required String name,
    required String slug,
    String? parentId,
    int? sortOrder,
    String? iconUrl,
    bool isActive = true,
  });

  /// Deactivates a category via admin API
  Future<CategoryItem> deactivateCategory(String id);

  /// Uploads a category image via admin API
  Future<CategoryItem> uploadCategoryImage({
    required String categoryId,
    required List<int> fileBytes,
    required String fileName,
  });

  /// Deletes a category image via admin API
  Future<CategoryItem> deleteCategoryImage(String categoryId);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final ApiClient apiClient;

  CategoryRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<CategoryItem>> getCategories({int? level, String? parentId}) async {
    final queryParams = <String, String>{
      'page': '0',
      'size': '100',
    };
    if (level != null) queryParams['level'] = level.toString();
    if (parentId != null && parentId.isNotEmpty) queryParams['parentId'] = parentId;

    final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final firstPageResponse = await apiClient.get(
      '${ApiEndpoints.categories}?$queryString',
      requiresAuth: false,
    );

    final rawData = firstPageResponse['data'];
    if (rawData is! Map<String, dynamic>) {
      throw const ApiException(message: 'Unexpected category response format from server.');
    }

    final allItems = <CategoryItem>[];
    final content = rawData['content'] as List<dynamic>? ?? [];
    for (final item in content) {
      if (item is Map<String, dynamic>) {
        allItems.add(CategoryItem.fromJson(item));
      }
    }

    final totalPages = (rawData['totalPages'] as num?)?.toInt() ?? 1;

    // If multiple pages exist (e.g. 286 categories across 3 pages of 100), fetch the remaining pages
    if (totalPages > 1) {
      final futures = <Future<Map<String, dynamic>>>[];
      for (int p = 1; p < totalPages; p++) {
        final nextParams = Map<String, String>.from(queryParams);
        nextParams['page'] = p.toString();
        final nextQuery = nextParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
        futures.add(apiClient.get('${ApiEndpoints.categories}?$nextQuery', requiresAuth: false));
      }

      final results = await Future.wait(futures);
      for (final res in results) {
        final data = res['data'];
        if (data is Map<String, dynamic>) {
          final cList = data['content'] as List<dynamic>? ?? [];
          for (final item in cList) {
            if (item is Map<String, dynamic>) {
              allItems.add(CategoryItem.fromJson(item));
            }
          }
        }
      }
    }

    return allItems;
  }

  @override
  Future<CategoryItem> getCategoryById(String id) async {
    final response = await apiClient.get(
      '${ApiEndpoints.categories}/$id',
      requiresAuth: false,
    );

    final rawData = response['data'];
    if (rawData is Map<String, dynamic>) {
      return CategoryItem.fromJson(rawData);
    }
    throw const ApiException(message: 'Failed to parse category response.');
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
    final body = <String, dynamic>{
      'name': name,
      'slug': slug,
      'isActive': isActive,
      'displayOrder': sortOrder ?? 0,
      'sortOrder': sortOrder ?? 0,
    };
    if (parentId != null && parentId.isNotEmpty) {
      body['parentId'] = parentId;
    }
    if (iconUrl != null && iconUrl.isNotEmpty) {
      body['iconUrl'] = iconUrl;
    }

    final response = await apiClient.post(
      ApiEndpoints.adminCategories,
      body: body,
      requiresAuth: true,
    );

    final rawData = response['data'];
    if (rawData is Map<String, dynamic>) {
      return CategoryItem.fromJson(rawData);
    }
    throw const ApiException(message: 'Failed to create category.');
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
    final body = <String, dynamic>{
      'name': name,
      'slug': slug,
      'isActive': isActive,
      'displayOrder': sortOrder ?? 0,
      'sortOrder': sortOrder ?? 0,
    };
    if (parentId != null && parentId.isNotEmpty) {
      body['parentId'] = parentId;
    }
    if (iconUrl != null && iconUrl.isNotEmpty) {
      body['iconUrl'] = iconUrl;
    }

    final response = await apiClient.put(
      '${ApiEndpoints.adminCategories}/$id',
      body: body,
      requiresAuth: true,
    );

    final rawData = response['data'];
    if (rawData is Map<String, dynamic>) {
      return CategoryItem.fromJson(rawData);
    }
    throw const ApiException(message: 'Failed to update category.');
  }

  @override
  Future<CategoryItem> deactivateCategory(String id) async {
    final response = await apiClient.delete(
      '${ApiEndpoints.adminCategories}/$id',
      requiresAuth: true,
    );

    final rawData = response['data'];
    if (rawData is Map<String, dynamic>) {
      return CategoryItem.fromJson(rawData);
    }
    throw const ApiException(message: 'Failed to deactivate category.');
  }

  @override
  Future<CategoryItem> uploadCategoryImage({
    required String categoryId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final extension = fileName.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
    final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';
    final response = await apiClient.postMultipart(
      ApiEndpoints.adminCategoryImage(categoryId),
      fileFieldName: 'file',
      fileBytes: fileBytes,
      fileName: fileName,
      contentType: contentType,
      requiresAuth: true,
    );

    final rawData = response['data'];
    if (rawData is Map<String, dynamic>) {
      return CategoryItem.fromJson(rawData);
    }
    throw const ApiException(message: 'Failed to upload category image.');
  }

  @override
  Future<CategoryItem> deleteCategoryImage(String categoryId) async {
    final response = await apiClient.delete(
      ApiEndpoints.adminCategoryImage(categoryId),
      requiresAuth: true,
    );

    final rawData = response['data'];
    if (rawData is Map<String, dynamic>) {
      return CategoryItem.fromJson(rawData);
    }
    throw const ApiException(message: 'Failed to delete category image.');
  }
}
