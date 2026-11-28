import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String identifier;
  final String password;
  final String? expectedRole; // 'ROLE_ADMIN' | 'ROLE_SALES_AGENT'

  const LoginSubmitted({
    required this.identifier,
    required this.password,
    this.expectedRole,
  });

  @override
  List<Object?> get props => [identifier, password, expectedRole];
}

class SalesPermissionsUpdated extends AuthEvent {
  final List<String> permissions;
  final bool active;

  const SalesPermissionsUpdated({
    required this.permissions,
    required this.active,
  });

  @override
  List<Object?> get props => [permissions, active];
}

class LogoutRequested extends AuthEvent {}
