import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/admin_user.dart';

abstract class AdminUserLocalDataSource {
  Future<AdminUserPageData?> getCachedUsers(String role);
  Future<void> cacheUsers(String role, AdminUserPageData data);
  Future<void> removeUserFromCache(String userId);
  Future<void> clearCache();
}

class AdminUserLocalDataSourceImpl implements AdminUserLocalDataSource {
  final SharedPreferences prefs;

  AdminUserLocalDataSourceImpl(this.prefs);

  static const String _userCachePrefix = 'cached_admin_users_';

  String _buildKey(String role) => '$_userCachePrefix${role.toUpperCase()}';

  @override
  Future<AdminUserPageData?> getCachedUsers(String role) async {
    final raw = prefs.getString(_buildKey(role));
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AdminUserPageData.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheUsers(String role, AdminUserPageData data) async {
    try {
      final encoded = jsonEncode(data.toJson());
      await prefs.setString(_buildKey(role), encoded);
    } catch (_) {}
  }

  @override
  Future<void> removeUserFromCache(String userId) async {
    try {
      final keys = prefs.getKeys().where((k) => k.startsWith(_userCachePrefix)).toList();
      for (final key in keys) {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) continue;
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final pageData = AdminUserPageData.fromJson(decoded);
        final filtered = pageData.content.where((u) => u.id != userId).toList();
        if (filtered.length != pageData.content.length) {
          final updated = AdminUserPageData(
            content: filtered,
            page: pageData.page,
            size: pageData.size,
            totalElements: pageData.totalElements > 0 ? pageData.totalElements - 1 : filtered.length,
            totalPages: pageData.totalPages,
            first: pageData.first,
            last: pageData.last,
          );
          await prefs.setString(key, jsonEncode(updated.toJson()));
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> clearCache() async {
    final keys = prefs.getKeys().where((k) => k.startsWith(_userCachePrefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
