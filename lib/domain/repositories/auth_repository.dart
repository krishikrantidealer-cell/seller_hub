import '../entities/auth_session.dart';

abstract class AuthRepository {
  /// Authenticate using email/identifier and password via /api/v1/auth/password/login
  Future<AuthSession> loginWithPassword({
    required String email,
    required String password,
    required bool rememberMe,
  });

  /// Check whether an active persisted session exists
  Future<AuthSession?> checkAuthStatus();

  /// Log out and clear persisted tokens
  Future<void> logout();

  /// Retrieve saved login identifier (if rememberMe was enabled)
  Future<String?> getSavedIdentifier();

  /// Retrieve rememberMe preference
  Future<bool> getRememberMe();
}
