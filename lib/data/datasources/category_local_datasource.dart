import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/category.dart';

abstract class CategoryLocalDataSource {
  Future<List<CategoryItem>?> getCachedCategories();
  Future<void> cacheCategories(List<CategoryItem> categories);
  Future<void> clearCache();
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  final SharedPreferences prefs;

  CategoryLocalDataSourceImpl(this.prefs);

  static const String _categoriesKey = 'cached_categories_data';

  @override
  Future<List<CategoryItem>?> getCachedCategories() async {
    final raw = prefs.getString(_categoriesKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => CategoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheCategories(List<CategoryItem> categories) async {
    try {
      final encoded = jsonEncode(categories.map((c) => c.toJson()).toList());
      await prefs.setString(_categoriesKey, encoded);
    } catch (_) {}
  }

  @override
  Future<void> clearCache() async {
    await prefs.remove(_categoriesKey);
  }
}
