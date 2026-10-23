import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seller_hub/domain/repositories/seller_auth_repository.dart';
import 'package:seller_hub/logic/auth/auth_bloc.dart';
import 'package:seller_hub/logic/auth/auth_event.dart';
import 'package:seller_hub/logic/auth/auth_state.dart';

class FakeSellerAuthRepository implements SellerAuthRepository {
  bool authenticated = false;
  String? token;
  String? sellerId;
  bool shouldFail = false;

  @override
  Future<Map<String, dynamic>> loginWithPassword({required String email, required String password}) async {
    if (shouldFail) throw Exception('Invalid credentials');
    authenticated = true;
    token = 'mock_jwt_token_123';
    sellerId = '6ab4ada822033f1670582bda';
    return {
      'token': token,
      'userId': sellerId,
      'email': email,
      'role': 'ROLE_SELLER',
    };
  }

  @override
  Future<bool> sendEmailOtp(String email) async {
    if (shouldFail) return false;
    return true;
  }

  @override
  Future<Map<String, dynamic>> verifyEmailOtp({required String email, required String otp}) async {
    if (shouldFail || otp != '123456') throw Exception('Invalid OTP');
    authenticated = true;
    token = 'mock_jwt_token_123';
    sellerId = '6ab4ada822033f1670582bda';
    return {
      'token': token,
      'userId': sellerId,
      'email': email,
      'role': 'ROLE_SELLER',
    };
  }

  @override
  Future<bool> setupPassword(String newPassword) async => true;

  @override
  Future<bool> forgotPassword(String email) async => true;

  @override
  Future<bool> resetPassword({required String token, required String newPassword}) async => true;

  @override
  Future<void> logout() async {
    authenticated = false;
    token = null;
    sellerId = null;
  }

  @override
  Future<bool> isAuthenticated() async => authenticated;

  @override
  Future<String?> getSavedToken() async => token;

  @override
  Future<String?> getSavedSellerId() async => sellerId;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthBloc Tests', () {
    late FakeSellerAuthRepository fakeAuthRepo;
    late AuthBloc authBloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeAuthRepo = FakeSellerAuthRepository();
      authBloc = AuthBloc(authRepository: fakeAuthRepo);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is initial', () {
      expect(authBloc.state.status, AuthStatus.initial);
    });

    test('LoginSubmitted with valid credentials logs in successfully', () async {
      final expectedStates = [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.authenticated)
            .having((s) => s.sellerId, 'sellerId', '6ab4ada822033f1670582bda'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const LoginSubmitted(
        identifier: 'seller@agribegri.com',
        password: 'Password123!',
        rememberMe: true,
      ));
    });

    test('LoginSubmitted with empty fields emits error state', () async {
      final expectedStates = [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', contains('Please enter valid credentials')),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const LoginSubmitted(
        identifier: '',
        password: '',
        rememberMe: false,
      ));
    });

    test('LogoutRequested emits unauthenticated and clears session', () async {
      fakeAuthRepo.authenticated = true;
      authBloc.emit(const AuthState(status: AuthStatus.authenticated, sellerId: '6ab4ada822033f1670582bda'));

      expectLater(
        authBloc.stream,
        emits(isA<AuthState>().having((s) => s.status, 'status', AuthStatus.unauthenticated)),
      );

      authBloc.add(LogoutRequested());
    });
  });
}
