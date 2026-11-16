import '../../core/constants/api_endpoints.dart';
import '../../core/di/injection_container.dart';
import '../../core/models/technical_name.dart';
import '../../core/network/api_client.dart';

/// Client service for Technical Name master records & commissions.
class TechnicalNameService {
  static final TechnicalNameService _instance = TechnicalNameService._internal();
  factory TechnicalNameService() => _instance;
  TechnicalNameService._internal();

  List<TechnicalNameModel>? _cachedSellerNames;
  List<TechnicalNameModel>? _cachedAdminNames;

  ApiClient get _apiClient => InjectionContainer.instance.apiClient;

  void invalidateCache() {
    _cachedSellerNames = null;
    _cachedAdminNames = null;
  }

  List<TechnicalNameModel> _parseList(Map<String, dynamic> response) {
    final raw = response['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => TechnicalNameModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<TechnicalNameModel>> fetchSellerTechnicalNames({
    String? search,
    String? category,
    String? letter,
    bool forceRefresh = false,
  }) async {
    final hasFilters = (search != null && search.trim().isNotEmpty) ||
        (category != null && category.trim().isNotEmpty) ||
        (letter != null && letter.trim().isNotEmpty);

    if (!forceRefresh && !hasFilters && _cachedSellerNames != null) {
      return _cachedSellerNames!;
    }

    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      query['category'] = category.trim();
    }
    if (letter != null && letter.trim().isNotEmpty) {
      query['letter'] = letter.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.sellerTechnicalNames,
      queryParameters: query.isEmpty ? null : query,
      requiresAuth: true,
    );
    final list = _parseList(response);
    if (!hasFilters) {
      _cachedSellerNames = list;
    }
    return list;
  }

  Future<List<TechnicalNameModel>> fetchAdminTechnicalNames({
    String? search,
    String? category,
    String? letter,
    bool activeOnly = false,
    bool forceRefresh = false,
  }) async {
    final hasFilters = (search != null && search.trim().isNotEmpty) ||
        (category != null && category.trim().isNotEmpty) ||
        (letter != null && letter.trim().isNotEmpty) ||
        activeOnly;

    if (!forceRefresh && !hasFilters && _cachedAdminNames != null) {
      return _cachedAdminNames!;
    }

    final query = <String, dynamic>{'activeOnly': activeOnly.toString()};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      query['category'] = category.trim();
    }
    if (letter != null && letter.trim().isNotEmpty) {
      query['letter'] = letter.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.adminTechnicalNames,
      queryParameters: query,
      requiresAuth: true,
    );
    final list = _parseList(response);
    if (!hasFilters) {
      _cachedAdminNames = list;
    }
    return list;
  }

  Future<TechnicalNameModel> createTechnicalName({
    required String name,
    required String category,
    required double commissionPercentage,
    bool isActive = true,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.adminTechnicalNames,
      body: {
        'name': name.trim(),
        'category': category.trim(),
        'commissionPercentage': commissionPercentage,
        'isActive': isActive,
      },
      requiresAuth: true,
    );
    invalidateCache();
    final data = response['data'];
    if (data is Map) {
      return TechnicalNameModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Invalid response when creating technical name');
  }

  Future<TechnicalNameModel> updateTechnicalName(
    String id, {
    String? name,
    String? category,
    double? commissionPercentage,
    bool? isActive,
    bool syncProducts = false,
  }) async {
    final body = <String, dynamic>{'syncProducts': syncProducts};
    if (name != null) body['name'] = name.trim();
    if (category != null) body['category'] = category.trim();
    if (commissionPercentage != null) {
      body['commissionPercentage'] = commissionPercentage;
    }
    if (isActive != null) body['isActive'] = isActive;

    final response = await _apiClient.put(
      ApiEndpoints.adminTechnicalNameById(id),
      body: body,
      requiresAuth: true,
    );
    invalidateCache();
    final data = response['data'];
    if (data is Map) {
      return TechnicalNameModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Invalid response when updating technical name');
  }

  Future<void> deleteTechnicalName(String id) async {
    await _apiClient.delete(
      ApiEndpoints.adminTechnicalNameById(id),
      requiresAuth: true,
    );
    invalidateCache();
  }

  Future<Map<String, dynamic>> importCsv(String csv) async {
    final response = await _apiClient.post(
      ApiEndpoints.adminTechnicalNamesImport,
      body: {'csv': csv},
      requiresAuth: true,
    );
    invalidateCache();
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }
}
