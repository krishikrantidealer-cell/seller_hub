import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String identifier;
  final String password;
  final bool rememberMe;

  const LoginSubmitted({
    required this.identifier,
    required this.password,
    required this.rememberMe,
  });

  @override
  List<Object?> get props => [identifier, password, rememberMe];
}

class OtpRequested extends AuthEvent {
  final String phoneNumber;
  const OtpRequested(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class OtpSubmitted extends AuthEvent {
  final String phoneNumber;
  final String otp;
  const OtpSubmitted({required this.phoneNumber, required this.otp});

  @override
  List<Object?> get props => [phoneNumber, otp];
}

class LogoutRequested extends AuthEvent {}
