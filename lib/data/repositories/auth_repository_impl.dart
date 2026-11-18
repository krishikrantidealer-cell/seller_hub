import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;
  final ApiClient? apiClient;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
    this.apiClient,
  });

  @override
  Future<AuthSession> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final responseDto = await remoteDataSource.loginWithPassword(
      email: email,
      password: password,
    );

    final session = responseDto.toDomain();

    // Persist session tokens & user metadata
    await tokenStorage.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      userId: session.userId,
      role: session.role,
      phoneNumber: session.phoneNumber,
    );

    return session;
  }

  @override
  Future<AuthSession?> checkAuthStatus() async {
    var accessToken = await tokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    if (TokenStorage.isJwtExpired(accessToken)) {
      if (apiClient == null) {
        await tokenStorage.clearSession();
        return null;
      }
      final refreshed = await apiClient!.refreshAccessToken();
      if (!refreshed) {
        return null;
      }
      accessToken = await tokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }
    }

    final refreshToken = await tokenStorage.getRefreshToken();
    final userId = await tokenStorage.getUserId();
    final role = await tokenStorage.getRole();
    final phoneNumber = await tokenStorage.getPhoneNumber();

    if (userId == null || userId.isEmpty) return null;

    return AuthSession(
      userId: userId,
      phoneNumber: phoneNumber,
      role: role ?? 'ROLE_ADMIN',
      accessToken: accessToken,
      refreshToken: refreshToken ?? '',
      tokenType: 'Bearer',
      expiresInMs: 86400000,
      isProfileComplete: true,
    );
  }

  @override
  Future<void> logout() async {
    await tokenStorage.clearSession();
  }
}
