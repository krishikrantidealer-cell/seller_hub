import 'package:equatable/equatable.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? sellerId;
  final String? token;
  final String? errorMessage;
  final bool isOtpSent;

  const AuthState({
    this.status = AuthStatus.initial,
    this.sellerId,
    this.token,
    this.errorMessage,
    this.isOtpSent = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? sellerId,
    String? token,
    String? errorMessage,
    bool? isOtpSent,
  }) {
    return AuthState(
      status: status ?? this.status,
      sellerId: sellerId ?? this.sellerId,
      token: token ?? this.token,
      errorMessage: errorMessage,
      isOtpSent: isOtpSent ?? this.isOtpSent,
    );
  }

  @override
  List<Object?> get props => [status, sellerId, token, errorMessage, isOtpSent];
}
