import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection_container.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/websocket_service.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  StreamSubscription<void>? _sessionExpiredSub;
  StreamSubscription<Map<String, dynamic>>? _salesPermSub;

  AuthBloc({
    required this.authRepository,
    Stream<void>? sessionExpiredStream,
  }) : super(const AuthState()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<SalesPermissionsUpdated>(_onSalesPermissionsUpdated);
    on<LogoutRequested>(_onLogoutRequested);

    try {
      final stream =
          sessionExpiredStream ?? InjectionContainer.instance.apiClient.onSessionExpired;
      _sessionExpiredSub = stream.listen((_) {
        if (!isClosed && state.status == AuthStatus.authenticated) {
          add(LogoutRequested());
        }
      });
      _salesPermSub = WebSocketService().salesPermissionUpdates.listen((payload) {
        if (isClosed || state.status != AuthStatus.authenticated || state.session == null) {
          return;
        }
        final data = payload['data'] is Map ? Map<String, dynamic>.from(payload['data'] as Map) : payload;
        final targetId = data['userId']?.toString() ?? '';
        if (targetId.isNotEmpty && targetId != state.session!.userId) {
          return;
        }
        final rawPerms = data['permissions'];
        final perms = rawPerms is List
            ? rawPerms.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
            : const <String>[];
        final active = data['active'] != false;
        add(SalesPermissionsUpdated(permissions: perms, active: active));
      });
    } catch (_) {}
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

      if (event.expectedRole == 'ROLE_SALES_AGENT' && !session.isSalesAgent) {
        await authRepository.logout();
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Please use a Sales Agent account for Sales Portal login.',
          validationErrors: null,
        ));
        return;
      }
      if (event.expectedRole == 'ROLE_ADMIN' && !session.isAdmin) {
        await authRepository.logout();
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Please switch to Sales Agent Login to sign in with a Sales account.',
          validationErrors: null,
        ));
        return;
      }

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

  Future<void> _onSalesPermissionsUpdated(
    SalesPermissionsUpdated event,
    Emitter<AuthState> emit,
  ) async {
    final current = state.session;
    if (current == null) return;
    if (!event.active) {
      add(LogoutRequested());
      return;
    }
    try {
      await InjectionContainer.instance.tokenStorage.savePermissions(event.permissions);
    } catch (_) {}
    emit(state.copyWith(
      session: current.copyWith(permissions: event.permissions),
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

  @override
  Future<void> close() {
    _sessionExpiredSub?.cancel();
    _salesPermSub?.cancel();
    return super.close();
  }
}
