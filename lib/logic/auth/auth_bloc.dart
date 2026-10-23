import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository})
      : super(const AuthState()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<OtpRequested>(_onOtpRequested);
    on<OtpSubmitted>(_onOtpSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final session = await authRepository.checkAuthStatus();
      if (session != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          session: session,
        ));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final cleanIdentifier = event.identifier.trim();
    final cleanPassword = event.password;

    if (cleanIdentifier.isEmpty || cleanPassword.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Please enter both your email/phone and password.',
      ));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      final session = await authRepository.loginWithPassword(
        email: cleanIdentifier,
        password: cleanPassword,
        rememberMe: event.rememberMe,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        session: session,
        errorMessage: null,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Login failed: ${e.toString()}',
      ));
    }
  }

  Future<void> _onOtpRequested(
    OtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    await Future.delayed(const Duration(milliseconds: 500));
    emit(state.copyWith(status: AuthStatus.unauthenticated, isOtpSent: true));
  }

  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    await Future.delayed(const Duration(milliseconds: 600));

    if (event.otp.length < 6) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid 6-digit OTP code',
      ));
      return;
    }

    emit(state.copyWith(
      status: AuthStatus.authenticated,
      isOtpSent: false,
    ));
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authRepository.logout();
    } catch (_) {}
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
