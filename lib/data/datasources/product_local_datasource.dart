import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/product.dart';

abstract class ProductLocalDataSource {
  Future<ProductPageData?> getCachedPage(int page, int size);
  Future<void> cachePage(int page, int size, ProductPageData pageData);
  Future<List<Product>?> getCachedFullCatalog();
  Future<void> cacheFullCatalog(List<Product> products);
  Future<void> updateCachedProduct(Product product);
  Future<void> removeCachedProduct(String productId);
  Future<void> clearCache();
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final SharedPreferences prefs;

  ProductLocalDataSourceImpl(this.prefs);

  static const String _pageKeyPrefix = 'cached_products_page_';
  static const String _fullCatalogKey = 'cached_full_catalog_products';

  String _buildPageKey(int page, int size) => '$_pageKeyPrefix${page}_$size';

  @override
  Future<List<Product>?> getCachedFullCatalog() async {
    final raw = prefs.getString(_fullCatalogKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheFullCatalog(List<Product> products) async {
    try {
      final encoded = jsonEncode(products.map((p) => p.toJson()).toList());
      await prefs.setString(_fullCatalogKey, encoded);
    } catch (_) {}
  }

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
      // Also update full catalog cache
      final rawFull = prefs.getString(_fullCatalogKey);
      if (rawFull != null && rawFull.isNotEmpty) {
        final list = (jsonDecode(rawFull) as List<dynamic>)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        final idx = list.indexWhere((p) =>
            (p.id.isNotEmpty && p.id == product.id) ||
            (p.productCode.isNotEmpty && p.productCode == product.productCode));
        if (idx != -1) {
          list[idx] = product;
          await cacheFullCatalog(list);
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> removeCachedProduct(String productId) async {
    try {
      final keys = prefs.getKeys().where((k) => k.startsWith(_pageKeyPrefix)).toList();
      for (final key in keys) {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) continue;
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final pageData = ProductPageData.fromJson(decoded);
        final list = List<Product>.from(pageData.content);
        final initialLength = list.length;
        list.removeWhere((p) => p.id == productId || p.productCode == productId);
        if (list.length != initialLength) {
          final updatedData = ProductPageData(
            content: list,
            page: pageData.page,
            size: pageData.size,
            totalElements: (pageData.totalElements > 0) ? pageData.totalElements - (initialLength - list.length) : 0,
            totalPages: pageData.totalPages,
            first: pageData.first,
            last: pageData.last,
            count: list.length,
          );
          await prefs.setString(key, jsonEncode(updatedData.toJson()));
        }
      }
      final rawFull = prefs.getString(_fullCatalogKey);
      if (rawFull != null && rawFull.isNotEmpty) {
        final list = (jsonDecode(rawFull) as List<dynamic>)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        final initialLength = list.length;
        list.removeWhere((p) => p.id == productId || p.productCode == productId);
        if (list.length != initialLength) {
          await cacheFullCatalog(list);
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> clearCache() async {
    await prefs.remove(_fullCatalogKey);
    final keys = prefs.getKeys().where((k) => k.startsWith(_pageKeyPrefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
