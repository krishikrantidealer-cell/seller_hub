import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthState()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginSubmitted>(_onLoginSubmitted);
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

    final fieldErrors = <String, String>{};
    if (cleanIdentifier.isEmpty) {
      fieldErrors['identifier'] = 'Admin email is required';
      fieldErrors['email'] = 'Admin email is required';
    } else if (cleanIdentifier.contains('@') &&
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(cleanIdentifier)) {
      fieldErrors['identifier'] = 'Please enter a valid email address';
      fieldErrors['email'] = 'Please enter a valid email address';
    }

    if (cleanPassword.isEmpty) {
      fieldErrors['password'] = 'Password is required';
    } else if (cleanPassword.length < 6) {
      fieldErrors['password'] = 'Password must be at least 6 characters';
    }

    if (fieldErrors.isNotEmpty) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Please enter valid admin credentials.',
        validationErrors: fieldErrors,
      ));
      return;
    }

    emit(state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
      validationErrors: null,
    ));

    try {
      final session = await authRepository.loginWithPassword(
        email: cleanIdentifier,
        password: cleanPassword,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        session: session,
        errorMessage: null,
        validationErrors: null,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
        validationErrors: e.validationErrors,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Login failed: ${e.toString()}',
        validationErrors: null,
      ));
    }
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
