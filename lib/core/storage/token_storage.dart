import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _keySellerToken = 'pref_seller_access_token';
  static const String _keyRefreshToken = 'pref_seller_refresh_token';
  static const String _keySellerId = 'pref_seller_id';
  static const String _keySellerEmail = 'pref_seller_email';
  static const String _keySellerPhone = 'pref_seller_phone';

  final SharedPreferences? _prefs;

  TokenStorage([this._prefs]);

  static Future<TokenStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TokenStorage(prefs);
  }

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    String? sellerId,
    String? email,
    String? phone,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_keySellerToken, accessToken);
    if (refreshToken != null) await prefs.setString(_keyRefreshToken, refreshToken);
    if (sellerId != null) await prefs.setString(_keySellerId, sellerId);
    if (email != null) await prefs.setString(_keySellerEmail, email);
    if (phone != null) await prefs.setString(_keySellerPhone, phone);
  }

  Future<String?> getAccessToken() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_keySellerToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  Future<String?> getSellerId() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_keySellerId);
  }

  Future<String?> getSellerEmail() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_keySellerEmail);
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_keySellerToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keySellerId);
    await prefs.remove(_keySellerEmail);
    await prefs.remove(_keySellerPhone);
  }
}
