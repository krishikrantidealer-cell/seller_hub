import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_session.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;
  final Map<String, String>? validationErrors;

  const AuthState({
    this.status = AuthStatus.initial,
    this.session,
    this.errorMessage,
    this.validationErrors,
  });

  /// Convenience getters for seamless backward compatibility with existing UI
  String? get sellerId => session?.userId;
  String? get token => session?.accessToken;

  String? getFieldError(String fieldName) => validationErrors?[fieldName];

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    String? errorMessage,
    Map<String, String>? validationErrors,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: errorMessage,
      validationErrors: validationErrors,
    );
  }

  @override
  List<Object?> get props => [
        status,
        session,
        errorMessage,
        validationErrors,
      ];
}
