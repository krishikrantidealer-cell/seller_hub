import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_session.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;
  final bool isOtpSent;

  const AuthState({
    this.status = AuthStatus.initial,
    this.session,
    this.errorMessage,
    this.isOtpSent = false,
  });

  /// Convenience getters for seamless backward compatibility with existing UI
  String? get sellerId => session?.userId;
  String? get token => session?.accessToken;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    String? errorMessage,
    bool? isOtpSent,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: errorMessage,
      isOtpSent: isOtpSent ?? this.isOtpSent,
    );
  }

  @override
  List<Object?> get props => [status, session, errorMessage, isOtpSent];
}
