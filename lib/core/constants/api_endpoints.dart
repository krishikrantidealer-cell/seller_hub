class ApiEndpoints {
  static const String baseUrl = 'https://ebs-biocrop-backend.onrender.com';
  static const String apiV1 = '$baseUrl/api/v1';

  // Health
  static const String health = '$apiV1/health';

  // Seller Auth
  static const String sellerPasswordLogin = '$apiV1/auth/password/login';
  static const String sellerEmailOtpSend = '$apiV1/auth/email/otp/send';
  static const String sellerEmailOtpVerify = '$apiV1/auth/email/otp/verify';
  static const String sellerPasswordSetup = '$apiV1/auth/password/setup';
  static const String sellerForgotPassword = '$apiV1/auth/password/forgot';
  static const String sellerPasswordReset = '$apiV1/auth/password/reset';
  static const String tokenRefresh = '$apiV1/auth/token/refresh';

  // Seller Catalog
  static const String sellerProducts = '$apiV1/seller/products';
  static String sellerProductById(String productId) => '$apiV1/seller/products/$productId';
  static String uploadProductImages(String productId) => '$apiV1/admin/products/$productId/images';

  // Seller Orders
  static const String sellerOrders = '$apiV1/seller/orders';
  static String sellerOrderById(String orderId) => '$apiV1/seller/orders/$orderId';

  // Categories
  static const String categories = '$apiV1/categories';
  static String categoryRoots({int level = 0}) => '$apiV1/categories?level=$level';
  static String categoryChildren(String parentId) => '$apiV1/categories?parentId=$parentId';
}
