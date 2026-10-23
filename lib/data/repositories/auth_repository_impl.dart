import '../../core/storage/token_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
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
    final hasToken = await tokenStorage.hasValidToken();
    if (!hasToken) return null;

    final accessToken = await tokenStorage.getAccessToken();
    final refreshToken = await tokenStorage.getRefreshToken();
    final userId = await tokenStorage.getUserId();
    final role = await tokenStorage.getRole();
    final phoneNumber = await tokenStorage.getPhoneNumber();

    if (accessToken == null || userId == null) return null;

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
