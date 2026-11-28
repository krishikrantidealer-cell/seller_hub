import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  final String userId;
  final String? phoneNumber;
  final String? email;
  final String? fullName;
  final String role;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInMs;
  final bool isProfileComplete;
  final List<String> permissions;

  const AuthSession({
    required this.userId,
    this.phoneNumber,
    this.email,
    this.fullName,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresInMs,
    required this.isProfileComplete,
    this.permissions = const [],
  });

  bool get isAdmin => role == 'ROLE_ADMIN' || role == 'ADMIN';
  bool get isSalesAgent => role == 'ROLE_SALES_AGENT' || role == 'SALES_AGENT';
  bool get isMarketing => role == 'ROLE_MARKETING' || role == 'MARKETING';
  bool get isStaff => isSalesAgent || isMarketing;

  bool hasPermission(String permission) => isAdmin || permissions.contains(permission);
  bool hasAnyPermission(List<String> keys) => isAdmin || keys.any(permissions.contains);

  AuthSession copyWith({
    String? userId,
    String? phoneNumber,
    String? email,
    String? fullName,
    String? role,
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    int? expiresInMs,
    bool? isProfileComplete,
    List<String>? permissions,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresInMs: expiresInMs ?? this.expiresInMs,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        phoneNumber,
        email,
        fullName,
        role,
        accessToken,
        refreshToken,
        tokenType,
        expiresInMs,
        isProfileComplete,
        permissions,
      ];
}
