import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';

class PincodeLookupResult {
  final String state;
  final String primaryCity;
  final List<String> cities;

  const PincodeLookupResult({
    required this.state,
    required this.primaryCity,
    required this.cities,
  });
}

/// Resolves Indian States, Cities, and 6-digit PIN codes via our own backend
/// (`/api/v1/locations/*`) with in-memory caching.
class IndiaLocationHelper {
  static const List<String> fallbackStates = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  static List<String>? _cachedStates;
  static final Map<String, List<String>> _cachedCitiesByState = {};

  static List<String> get states => _cachedStates ?? fallbackStates;

  static Future<List<String>> fetchStates() async {
    if (_cachedStates != null && _cachedStates!.isNotEmpty) {
      return _cachedStates!;
    }
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.indiaStates}');
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map ? decoded['data'] : null;
        if (data is List) {
          final parsed = data
              .map((s) => s?.toString().trim() ?? '')
              .where((s) => s.isNotEmpty)
              .toList()
            ..sort();
          if (parsed.isNotEmpty) {
            _cachedStates = parsed;
            return parsed;
          }
        }
      }
    } catch (_) {}
    return fallbackStates;
  }

  static Future<List<String>> fetchCitiesForState(
    String state, {
    List<String> extraCities = const [],
  }) async {
    final normState = normalizeState(state);
    if (normState.isEmpty) return [];

    List<String>? cached = _cachedCitiesByState[normState];
    if (cached == null) {
      try {
        final uri = Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.indiaCities(normState)}',
        );
        final response = await http
            .get(uri, headers: const {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final data = decoded is Map ? decoded['data'] : null;
          if (data is List) {
            final parsed = data
                .map((e) => e?.toString().trim() ?? '')
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
            if (parsed.isNotEmpty) {
              _cachedCitiesByState[normState] = parsed;
              cached = parsed;
            }
          }
        }
      } catch (_) {}
    }

    final merged = <String>{...(cached ?? const <String>[])};
    for (final c in extraCities) {
      final t = c.trim();
      if (t.isNotEmpty && t.toLowerCase() != 'na') {
        merged.add(t);
      }
    }
    return merged.toList()..sort();
  }

  static List<String> cachedCitiesForState(
    String state, {
    List<String> extraCities = const [],
  }) {
    final normState = normalizeState(state);
    final base = _cachedCitiesByState[normState] ?? const <String>[];
    final merged = <String>{...base};
    for (final c in extraCities) {
      final t = c.trim();
      if (t.isNotEmpty && t.toLowerCase() != 'na') {
        merged.add(t);
      }
    }
    return merged.toList()..sort();
  }

  static String normalizeState(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final lower = trimmed.toLowerCase();
    for (final state in states) {
      if (state.toLowerCase() == lower) return state;
    }
    if (lower.contains('delhi')) return 'Delhi';
    if (lower.contains('jammu')) return 'Jammu and Kashmir';
    if (lower.contains('andaman')) return 'Andaman and Nicobar Islands';
    if (lower.contains('dadra') || lower.contains('daman') || lower.contains('diu')) {
      return 'Dadra and Nagar Haveli and Daman and Diu';
    }
    if (lower == 'orissa') return 'Odisha';
    if (lower == 'pondicherry') return 'Puducherry';
    return trimmed;
  }

  static Future<PincodeLookupResult?> lookupPincode(String pincode) async {
    final clean = pincode.trim();
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(clean)) {
      return null;
    }
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.pincodeLookup(clean)}');
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 7));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map ? decoded['data'] : null;
        if (data is Map) {
          final resolvedState = normalizeState(data['state']?.toString() ?? '');
          final primaryCity = (data['primaryCity']?.toString() ?? '').trim();
          final rawCities = data['cities'];
          final cities = rawCities is List
              ? rawCities.map((e) => e?.toString().trim() ?? '').where((e) => e.isNotEmpty).toList()
              : <String>[];

          if (resolvedState.isNotEmpty) {
            if (cities.isNotEmpty) {
              _cachedCitiesByState[resolvedState] = cities;
            }
            return PincodeLookupResult(
              state: resolvedState,
              primaryCity: primaryCity.isNotEmpty ? primaryCity : (cities.isNotEmpty ? cities.first : ''),
              cities: cities,
            );
          }
        }
      }
    } catch (_) {}

    // Fallback to India Post directly when local/un-redeployed backend does not yet expose /api/v1/locations/pincode
    try {
      final postUri = Uri.parse('https://api.postalpincode.in/pincode/$clean');
      final postResp = await http.get(postUri).timeout(const Duration(seconds: 6));
      if (postResp.statusCode != 200) return null;
      final decoded = jsonDecode(postResp.body);
      if (decoded is! List || decoded.isEmpty) return null;
      final first = decoded.first;
      if (first is! Map || first['Status'] != 'Success') return null;
      final offices = first['PostOffice'];
      if (offices is! List || offices.isEmpty) return null;

      String resolvedState = '';
      String primaryCity = '';
      final extraCities = <String>{};

      for (final po in offices) {
        if (po is! Map) continue;
        final st = normalizeState(po['State']?.toString() ?? '');
        if (resolvedState.isEmpty && st.isNotEmpty) resolvedState = st;
        final district = (po['District']?.toString() ?? '').trim();
        final block = (po['Block']?.toString() ?? '').trim();
        if (district.isNotEmpty && district.toLowerCase() != 'na') {
          if (primaryCity.isEmpty) primaryCity = district;
          extraCities.add(district);
        }
        if (block.isNotEmpty && block.toLowerCase() != 'na') {
          extraCities.add(block);
        }
      }

      if (resolvedState.isEmpty) return null;
      if (primaryCity.isEmpty && extraCities.isNotEmpty) {
        primaryCity = extraCities.first;
      }

      final cities = await fetchCitiesForState(resolvedState, extraCities: extraCities.toList());
      return PincodeLookupResult(
        state: resolvedState,
        primaryCity: primaryCity,
        cities: cities,
      );
    } catch (_) {
      return null;
    }
  }
}
