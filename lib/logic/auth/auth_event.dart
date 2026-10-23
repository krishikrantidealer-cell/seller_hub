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

  const LoginSubmitted({
    required this.identifier,
    required this.password,
  });

  @override
  List<Object?> get props => [identifier, password];
}

class LogoutRequested extends AuthEvent {}
