import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  final String userId;
  final String? phoneNumber;
  final String role;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInMs;
  final bool isProfileComplete;

  const AuthSession({
    required this.userId,
    this.phoneNumber,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresInMs,
    required this.isProfileComplete,
  });

  bool get isAdmin => role == 'ROLE_ADMIN' || role == 'ADMIN';

  @override
  List<Object?> get props => [
        userId,
        phoneNumber,
        role,
        accessToken,
        refreshToken,
        tokenType,
        expiresInMs,
        isProfileComplete,
      ];
}
