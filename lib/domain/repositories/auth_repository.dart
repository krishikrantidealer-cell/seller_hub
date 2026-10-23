import '../entities/auth_session.dart';

abstract class AuthRepository {
  /// Authenticate using email and password via /api/v1/auth/password/login
  Future<AuthSession> loginWithPassword({
    required String email,
    required String password,
  });

  /// Check whether an active persisted session exists
  Future<AuthSession?> checkAuthStatus();

  /// Log out and clear persisted tokens
  Future<void> logout();
}
