class ApiEndpoints {
  /// Base URL for the backend API, configurable via --dart-define=API_BASE_URL=http://...
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Authentication
  static const String loginPassword = '/api/v1/auth/password/login';
}
