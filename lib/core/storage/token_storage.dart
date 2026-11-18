import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class TokenStorage {
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyRole = 'auth_user_role';
  static const String _keyPhoneNumber = 'auth_phone_number';

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
  }) async {
    final prefs = await _instance;
    await Future.wait([
      prefs.setString(_keyAccessToken, accessToken),
      prefs.setString(_keyRefreshToken, refreshToken),
      prefs.setString(_keyUserId, userId),
      prefs.setString(_keyRole, role),
      if (phoneNumber != null) prefs.setString(_keyPhoneNumber, phoneNumber),
    ]);
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
