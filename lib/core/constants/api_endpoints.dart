class ApiEndpoints {
  /// Base URL for the backend API, configurable via --dart-define=API_BASE_URL=https://...
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ebs-biocrop-backend.onrender.com',
  );

  /// Authentication
  static const String loginPassword = '/api/v1/auth/password/login';

  /// Products
  static const String products = '/api/v1/products';

  /// Collections
  static const String collections = '/api/v1/collections';
  static const String adminCollections = '/api/v1/admin/collections';
  static String productCollections(String productId) =>
      '/api/v1/admin/products/$productId/collections';

  /// Categories
  static const String categories = '/api/v1/categories';
  static const String adminCategories = '/api/v1/admin/categories';
  static String adminCategoryImage(String categoryId) =>
      '/api/v1/admin/categories/$categoryId/image';

  /// Admin Users (Sellers & Customers)
  static const String adminUsers = '/api/v1/admin/users';
  static String adminUserBlock(String userId) => '/api/v1/admin/users/$userId/block';
  static String adminUserDeletion(String userId) => '/api/v1/admin/users/$userId/deletion';
}
