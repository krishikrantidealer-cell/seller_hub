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
}
