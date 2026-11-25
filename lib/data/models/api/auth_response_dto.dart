import '../../../domain/entities/auth_session.dart';

class AuthResponseDto {
  final bool success;
  final String message;
  final AuthDataDto? data;
  final String? timestamp;

  const AuthResponseDto({
    required this.success,
    required this.message,
    this.data,
    this.timestamp,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? AuthDataDto.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
        'timestamp': timestamp,
      };

  AuthSession toDomain() {
    if (data == null) {
      throw StateError('Cannot map AuthResponseDto to AuthSession: data is null');
    }
    return data!.toDomain();
  }
}

class AuthDataDto {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInMs;
  final String userId;
  final String? phoneNumber;
  final String? email;
  final String? fullName;
  final String role;
  final bool isProfileComplete;
  final List<String> permissions;

  const AuthDataDto({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresInMs,
    required this.userId,
    this.phoneNumber,
    this.email,
    this.fullName,
    required this.role,
    required this.isProfileComplete,
    this.permissions = const [],
  });

  factory AuthDataDto.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final perms = rawPerms is List
        ? rawPerms.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const <String>[];
    return AuthDataDto(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresInMs: (json['expiresInMs'] as num?)?.toInt() ?? 86400000,
      userId: json['userId'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      role: json['role'] as String? ?? 'ROLE_ADMIN',
      isProfileComplete: json['isProfileComplete'] as bool? ?? true,
      permissions: perms,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'tokenType': tokenType,
        'expiresInMs': expiresInMs,
        'userId': userId,
        'phoneNumber': phoneNumber,
        'email': email,
        'fullName': fullName,
        'role': role,
        'isProfileComplete': isProfileComplete,
        'permissions': permissions,
      };

  AuthSession toDomain() {
    return AuthSession(
      userId: userId,
      phoneNumber: phoneNumber,
      email: email,
      fullName: fullName,
      role: role,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresInMs: expiresInMs,
      isProfileComplete: isProfileComplete,
      permissions: permissions,
    );
  }
}
