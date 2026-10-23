import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/core/network/api_exception.dart';
import 'package:seller_hub/domain/entities/auth_session.dart';
import 'package:seller_hub/domain/repositories/auth_repository.dart';
import 'package:seller_hub/logic/auth/auth_bloc.dart';
import 'package:seller_hub/logic/auth/auth_event.dart';
import 'package:seller_hub/logic/auth/auth_state.dart';

class MockAuthRepository implements AuthRepository {
  AuthSession? mockSession;
  bool shouldThrow = false;
  String errorMessage = 'Invalid credentials';
  bool rememberMeValue = true;
  String? savedIdentifier;

  @override
  Future<AuthSession> loginWithPassword({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage, statusCode: 401);
    }
    final session = mockSession ??
        AuthSession(
          userId: '6ab4ae6922033f1670582bdb',
          phoneNumber: '9876543668',
          role: 'ROLE_ADMIN',
          accessToken: 'mock_access_token',
          refreshToken: 'mock_refresh_token',
          tokenType: 'Bearer',
          expiresInMs: 86400000,
          isProfileComplete: true,
        );
    mockSession = session;
    rememberMeValue = rememberMe;
    savedIdentifier = email;
    return session;
  }

  @override
  Future<AuthSession?> checkAuthStatus() async {
    return mockSession;
  }

  @override
  Future<void> logout() async {
    mockSession = null;
  }

  @override
  Future<String?> getSavedIdentifier() async => savedIdentifier;

  @override
  Future<bool> getRememberMe() async => rememberMeValue;
}

void main() {
  late MockAuthRepository repository;
  late AuthBloc authBloc;

  setUp(() {
    repository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: repository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc - Admin Password Login', () {
    test('initial state has AuthStatus.initial', () {
      expect(authBloc.state.status, AuthStatus.initial);
      expect(authBloc.state.session, isNull);
    });

    test('LoginSubmitted with valid credentials emits loading then authenticated', () async {
      final expectedStates = [
        const AuthState(status: AuthStatus.loading),
        predicate<AuthState>((state) =>
            state.status == AuthStatus.authenticated &&
            state.session != null &&
            state.session!.userId == '6ab4ae6922033f1670582bdb' &&
            state.session!.role == 'ROLE_ADMIN'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const LoginSubmitted(
        identifier: 'admin1email@example.com',
        password: 'Admin!Pass123',
        rememberMe: true,
      ));
    });

    test('LoginSubmitted with empty fields emits error without calling repository', () async {
      final expectedStates = [
        predicate<AuthState>((state) =>
            state.status == AuthStatus.error &&
            state.errorMessage == 'Please enter both your email/phone and password.'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const LoginSubmitted(
        identifier: '',
        password: '',
        rememberMe: true,
      ));
    });

    test('LoginSubmitted on ApiException emits loading then error with server message', () async {
      repository.shouldThrow = true;
      repository.errorMessage = 'Bad credentials. Please check your password.';

      final expectedStates = [
        const AuthState(status: AuthStatus.loading),
        predicate<AuthState>((state) =>
            state.status == AuthStatus.error &&
            state.errorMessage == 'Bad credentials. Please check your password.'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const LoginSubmitted(
        identifier: 'admin1email@example.com',
        password: 'WrongPassword',
        rememberMe: false,
      ));
    });

    test('CheckAuthStatus emits authenticated when active session exists', () async {
      repository.mockSession = const AuthSession(
        userId: '6ab4ae6922033f1670582bdb',
        role: 'ROLE_ADMIN',
        accessToken: 'saved_token',
        refreshToken: 'saved_refresh',
        tokenType: 'Bearer',
        expiresInMs: 86400000,
        isProfileComplete: true,
      );

      final expectedStates = [
        predicate<AuthState>((state) =>
            state.status == AuthStatus.authenticated &&
            state.session?.accessToken == 'saved_token'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(CheckAuthStatus());
    });

    test('LogoutRequested clears session and emits unauthenticated', () async {
      final expectedStates = [
        const AuthState(status: AuthStatus.unauthenticated),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(LogoutRequested());
    });
  });
}
