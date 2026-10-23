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
  ApiException? exceptionToThrow;
  String errorMessage = 'Invalid credentials';

  @override
  Future<AuthSession> loginWithPassword({
    required String email,
    required String password,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? ApiException(message: errorMessage, statusCode: 401);
    }
    final session = mockSession ??
        const AuthSession(
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
      ));
    });

    test('LoginSubmitted with empty fields emits error without calling repository', () async {
      final expectedStates = [
        predicate<AuthState>((state) =>
            state.status == AuthStatus.error &&
            state.errorMessage == 'Please enter valid admin credentials.' &&
            state.getFieldError('email') == 'Admin email is required' &&
            state.getFieldError('password') == 'Password is required'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const LoginSubmitted(
        identifier: '',
        password: '',
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
      ));
    });

    test('LoginSubmitted on ValidationException emits error with field-level validationErrors', () async {
      repository.shouldThrow = true;
      repository.exceptionToThrow = const ValidationException(
        message: 'Validation failed for one or more fields',
        validationErrors: {'email': 'Email must be a well-formed email address'},
      );

      final expectedStates = [
        const AuthState(status: AuthStatus.loading),
        predicate<AuthState>((state) =>
            state.status == AuthStatus.error &&
            state.errorMessage == 'Validation failed for one or more fields' &&
            state.getFieldError('email') == 'Email must be a well-formed email address'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const LoginSubmitted(
        identifier: 'admin1email@example.com',
        password: 'Admin!Pass123',
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
