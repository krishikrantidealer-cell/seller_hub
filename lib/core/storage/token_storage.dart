import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class TokenStorage {
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyRole = 'auth_user_role';
  static const String _keyPhoneNumber = 'auth_phone_number';
  static const String _keyEmail = 'auth_user_email';
  static const String _keyFullName = 'auth_user_full_name';
  static const String _keyPermissions = 'auth_user_permissions';

  final SharedPreferences? prefs;

  TokenStorage({this.prefs});

  Future<SharedPreferences> get _instance async {
    return prefs ?? await SharedPreferences.getInstance();
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String role,
    String? phoneNumber,
    String? email,
    String? fullName,
    List<String> permissions = const [],
  }) async {
    final prefs = await _instance;
    await Future.wait([
      prefs.setString(_keyAccessToken, accessToken),
      prefs.setString(_keyRefreshToken, refreshToken),
      prefs.setString(_keyUserId, userId),
      prefs.setString(_keyRole, role),
      if (phoneNumber != null) prefs.setString(_keyPhoneNumber, phoneNumber),
      if (email != null) prefs.setString(_keyEmail, email),
      if (fullName != null) prefs.setString(_keyFullName, fullName),
      prefs.setStringList(_keyPermissions, permissions),
    ]);
  }

  Future<void> savePermissions(List<String> permissions) async {
    final prefs = await _instance;
    await prefs.setStringList(_keyPermissions, permissions);
  }

  Future<List<String>> getPermissions() async {
    final prefs = await _instance;
    return prefs.getStringList(_keyPermissions) ?? const [];
  }

  Future<String?> getEmail() async {
    final prefs = await _instance;
    return prefs.getString(_keyEmail);
  }

  Future<String?> getFullName() async {
    final prefs = await _instance;
    return prefs.getString(_keyFullName);
  }

  Future<String?> getAccessToken() async {
    final prefs = await _instance;
    return prefs.getString(_keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _instance;
    return prefs.getString(_keyRefreshToken);
  }

  Future<String?> getUserId() async {
    final prefs = await _instance;
    return prefs.getString(_keyUserId);
  }

  Future<String?> getRole() async {
    final prefs = await _instance;
    return prefs.getString(_keyRole);
  }

  Future<String?> getPhoneNumber() async {
    final prefs = await _instance;
    return prefs.getString(_keyPhoneNumber);
  }

  static bool isJwtExpired(
    String token, {
    Duration skew = const Duration(seconds: 30),
  }) {
    final parts = token.split('.');
    if (parts.length != 3) return false;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (payload is! Map<String, dynamic>) return false;
      final exp = payload['exp'];
      if (exp is! num) return false;
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
      return DateTime.now().toUtc().add(skew).isAfter(expiry);
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    if (token != null && token.isNotEmpty && !isJwtExpired(token)) {
      return true;
    }
    final refresh = await getRefreshToken();
    return refresh != null && refresh.isNotEmpty && !isJwtExpired(refresh);
  }

  Future<void> clearSession() async {
    final prefs = await _instance;
    await Future.wait([
      prefs.remove(_keyAccessToken),
      prefs.remove(_keyRefreshToken),
      prefs.remove(_keyUserId),
      prefs.remove(_keyRole),
      prefs.remove(_keyPhoneNumber),
    ]);
  }

  Future<void> saveRememberMe({required bool rememberMe, String? identifier}) async {
    final prefs = await _instance;
    await prefs.setBool(AppConstants.prefRememberMe, rememberMe);
    if (rememberMe && identifier != null && identifier.isNotEmpty) {
      await prefs.setString(AppConstants.prefSavedIdentifier, identifier);
    } else {
      await prefs.remove(AppConstants.prefSavedIdentifier);
    }
  }

  Future<bool> getRememberMe() async {
    final prefs = await _instance;
    return prefs.getBool(AppConstants.prefRememberMe) ?? true;
  }

  Future<String?> getSavedIdentifier() async {
    final prefs = await _instance;
    return prefs.getString(AppConstants.prefSavedIdentifier);
  }
}
