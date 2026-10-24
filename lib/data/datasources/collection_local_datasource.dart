import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/collection.dart';

abstract class CollectionLocalDataSource {
  Future<CollectionsData?> getCachedCollections();
  Future<void> cacheCollections(CollectionsData collectionsData);
  Future<void> updateCachedCollection(CollectionItem collection);
  Future<void> clearCache();
}

class CollectionLocalDataSourceImpl implements CollectionLocalDataSource {
  final SharedPreferences prefs;

  CollectionLocalDataSourceImpl(this.prefs);

  static const String _collectionsKey = 'cached_collections_data';

  @override
  Future<CollectionsData?> getCachedCollections() async {
    final raw = prefs.getString(_collectionsKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return CollectionsData.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheCollections(CollectionsData collectionsData) async {
    try {
      final encoded = jsonEncode(collectionsData.toJson());
      await prefs.setString(_collectionsKey, encoded);
    } catch (_) {}
  }

  @override
  Future<void> updateCachedCollection(CollectionItem collection) async {
    try {
      final current = await getCachedCollections();
      if (current == null) return;

      final items = List<CollectionItem>.from(current.items);
      final idx = items.indexWhere((c) => c.id == collection.id);
      if (idx != -1) {
        items[idx] = collection;
      } else {
        items.insert(0, collection);
      }

      await cacheCollections(CollectionsData(
        count: items.length,
        items: items,
      ));
    } catch (_) {}
  }

  @override
  Future<void> clearCache() async {
    await prefs.remove(_collectionsKey);
  }
}
