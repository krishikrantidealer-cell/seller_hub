class ApiEndpoints {
  /// Base URL for the backend API, configurable via --dart-define=API_BASE_URL=https://...
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Authentication
  static const String loginPassword = '/api/v1/auth/password/login';
  static const String refreshToken = '/api/v1/auth/token/refresh';

  /// Orders
  static const String adminOrders = '/api/v1/admin/orders';
  static String adminCreateOrderForCustomer(String customerId) =>
      '/api/v1/admin/orders/customers/$customerId/create';
  static String adminOrderConfirm(String orderId) => '/api/v1/admin/orders/$orderId/confirm';
  static String adminOrderVelocityShipment(String orderId) =>
      '/api/v1/admin/orders/$orderId/shipment/velocity';
  static String adminOrderLabel(String orderId) => '/api/v1/admin/orders/$orderId/label';
  static String adminOrderSyncTracking(String orderId) =>
      '/api/v1/admin/orders/$orderId/sync-tracking';
  static String adminOrderRtoRestock(String orderId) =>
      '/api/v1/admin/orders/$orderId/rto/restock';
  static String adminOrderCancel(String orderId) => '/api/v1/admin/orders/$orderId/cancel';

  /// Products
  static const String products = '/api/v1/products';
  static const String adminProducts = '/api/v1/admin/products';
  static const String adminProductsReorder = '/api/v1/admin/products/reorder';
  static const String adminProductsPermanent = '/api/v1/admin/products/permanent';
  static String adminProduct(String productId) => '/api/v1/admin/products/$productId';
  static String adminProductPermanent(String productId) =>
      '/api/v1/admin/products/$productId/permanent';
  static String adminProductAvailability(String productId) =>
      '/api/v1/admin/products/$productId/availability';
  static String adminProductVariantDefault(String productId, String variantId) =>
      '/api/v1/admin/products/$productId/variants/$variantId/default';
  static String adminProductReview(String productId) =>
      '/api/v1/admin/products/$productId/review';
  static String adminProductImages(String productId) =>
      '/api/v1/admin/products/$productId/images';

  /// Collections
  static const String collections = '/api/v1/collections';
  static const String adminCollections = '/api/v1/admin/collections';
  static String productCollections(String productId) =>
      '/api/v1/admin/products/$productId/collections';
  static String adminCollectionImage(String collectionId) =>
      '/api/v1/admin/collections/$collectionId/image';
  static String adminSubCollectionImage(String collectionId, String subCollectionId) =>
      '/api/v1/admin/collections/$collectionId/subcollections/$subCollectionId/image';
  static const String adminCollectionUploadImage =
      '/api/v1/admin/collections/upload-image';

  /// Categories
  static const String categories = '/api/v1/categories';
  static const String adminCategories = '/api/v1/admin/categories';
  static String adminCategoryImage(String categoryId) =>
      '/api/v1/admin/categories/$categoryId/image';

  // Hero Banners
  static const String adminBanners = '/api/v1/admin/banners';
  static const String adminBannersReorder = '/api/v1/admin/banners/reorder';
  static String adminBannerById(String bannerId) => '/api/v1/admin/banners/$bannerId';
  static String adminBannerImage(String bannerId) => '/api/v1/admin/banners/$bannerId/image';
  static String adminBannerToggle(String bannerId) => '/api/v1/admin/banners/$bannerId/toggle';

  // Technical Names
  static const String technicalNames = '/api/v1/technical-names';
  static const String sellerTechnicalNames = '/api/v1/seller/technical-names';
  static const String adminTechnicalNames = '/api/v1/admin/technical-names';
  static String adminTechnicalNameById(String id) =>
      '/api/v1/admin/technical-names/$id';
  static const String adminTechnicalNamesImport =
      '/api/v1/admin/technical-names/import';

  // Variant Labels
  static const String variantLabels = '/api/v1/variant-labels';
  static String variantLabelById(String id) => '/api/v1/variant-labels/$id';

  /// Admin Users (Sellers & Customers)
  static const String adminUsers = '/api/v1/admin/users';
  static const String adminCreateCustomer = '/api/v1/admin/users/customers';
  static const String adminCreateSeller = '/api/v1/admin/users/sellers';
  static String adminUserBlock(String userId) => '/api/v1/admin/users/$userId/block';
  static String adminUserById(String userId) => '/api/v1/admin/users/$userId';
  static String adminUserDeletion(String userId) => '/api/v1/admin/users/$userId/deletion';
  static String adminUserPermanentDeletion(String userId) => '/api/v1/admin/users/$userId/permanent';
  static String adminSellerDocuments(String userId) => '/api/v1/admin/users/$userId/kyc-documents';
  static String adminSellerDocumentDownload(String userId, String documentType, int index) =>
      '/api/v1/admin/users/$userId/kyc-documents/$documentType/$index';

  /// Sales Agents & RBAC
  static const String adminSalesAgents = '/api/v1/admin/sales-agents';
  static String adminSalesAgentPermissions(String id) => '/api/v1/admin/sales-agents/$id/permissions';
  static String adminSalesAgentStatus(String id) => '/api/v1/admin/sales-agents/$id/status';
  static String adminSalesAgentById(String id) => '/api/v1/admin/sales-agents/$id';

  /// Locations (Indian States, Cities & PIN Code Lookup)
  static const String indiaStates = '/api/v1/locations/india/states';
  static String indiaCities(String state) =>
      '/api/v1/locations/india/cities?state=${Uri.encodeQueryComponent(state)}';
  static String pincodeLookup(String pincode) => '/api/v1/locations/pincode/$pincode';
}
