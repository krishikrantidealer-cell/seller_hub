import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<OtpRequested>(_onOtpRequested);
    on<OtpSubmitted>(_onOtpSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    // Simulate async network / webhook roundtrip
    await Future.delayed(const Duration(milliseconds: 600));

    if (event.identifier.isEmpty || event.password.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Please enter valid credentials',
      ));
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefRememberMe, event.rememberMe);
      if (event.rememberMe) {
        await prefs.setString(AppConstants.prefSavedIdentifier, event.identifier);
      } else {
        await prefs.remove(AppConstants.prefSavedIdentifier);
      }
    } catch (_) {}

    emit(state.copyWith(
      status: AuthStatus.authenticated,
      sellerId: 'SELLER-AGRI-8821',
      token: 'jwt_mock_token_seller_hub_2026',
    ));
  }

  Future<void> _onOtpRequested(OtpRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    await Future.delayed(const Duration(milliseconds: 500));
    emit(state.copyWith(status: AuthStatus.unauthenticated, isOtpSent: true));
  }

  Future<void> _onOtpSubmitted(OtpSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    await Future.delayed(const Duration(milliseconds: 600));

    if (event.otp.length < 6) {
      emit(state.copyWith(status: AuthStatus.error, errorMessage: 'Invalid 6-digit OTP code'));
      return;
    }

    emit(state.copyWith(
      status: AuthStatus.authenticated,
      sellerId: 'SELLER-AGRI-8821',
      token: 'jwt_mock_token_seller_hub_2026',
      isOtpSent: false,
    ));
  }

  void _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) {
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
