import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/product.dart';

abstract class ProductLocalDataSource {
  Future<ProductPageData?> getCachedPage(int page, int size);
  Future<void> cachePage(int page, int size, ProductPageData pageData);
  Future<void> updateCachedProduct(Product product);
  Future<void> clearCache();
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final SharedPreferences prefs;

  ProductLocalDataSourceImpl(this.prefs);

  static const String _pageKeyPrefix = 'cached_products_page_';

  String _buildPageKey(int page, int size) => '$_pageKeyPrefix${page}_$size';

  @override
  Future<ProductPageData?> getCachedPage(int page, int size) async {
    // Check specific page/size key first
    var raw = prefs.getString(_buildPageKey(page, size));
    // If not found and asking for page 0, check latest fallback
    if ((raw == null || raw.isEmpty) && page == 0) {
      raw = prefs.getString('${_pageKeyPrefix}latest');
    }
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return ProductPageData.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cachePage(int page, int size, ProductPageData pageData) async {
    try {
      final encoded = jsonEncode(pageData.toJson());
      await prefs.setString(_buildPageKey(page, size), encoded);
      if (page == 0) {
        await prefs.setString('${_pageKeyPrefix}latest', encoded);
      }
    } catch (_) {}
  }

  @override
  Future<void> updateCachedProduct(Product product) async {
    try {
      final keys = prefs.getKeys().where((k) => k.startsWith(_pageKeyPrefix)).toList();
      for (final key in keys) {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) continue;
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final pageData = ProductPageData.fromJson(decoded);
        final list = List<Product>.from(pageData.content);
        final idx = list.indexWhere((p) =>
            (p.id.isNotEmpty && p.id == product.id) ||
            (p.productCode.isNotEmpty && p.productCode == product.productCode));
        if (idx != -1) {
          list[idx] = product;
          final updatedData = ProductPageData(
            content: list,
            page: pageData.page,
            size: pageData.size,
            totalElements: pageData.totalElements,
            totalPages: pageData.totalPages,
            first: pageData.first,
            last: pageData.last,
            count: list.length,
          );
          await prefs.setString(key, jsonEncode(updatedData.toJson()));
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> clearCache() async {
    final keys = prefs.getKeys().where((k) => k.startsWith(_pageKeyPrefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
