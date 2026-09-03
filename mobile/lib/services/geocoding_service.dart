import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';

class GeocodedPlace {
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? country;

  const GeocodedPlace({
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.country,
  });

  factory GeocodedPlace.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? json['city'] ?? 'Unknown').toString();
    final display = (json['display_name'] ?? name).toString();
    return GeocodedPlace(
      name: name,
      displayName: display,
      latitude: _asDouble(json['latitude'] ?? json['lat']) ?? 0,
      longitude: _asDouble(json['longitude'] ?? json['lon']) ?? 0,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
    );
  }

  bool get isValid =>
      name.isNotEmpty &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Forward-geocodes any city/locality. Tries the Mausam backend first, then
/// Open-Meteo, then Nominatim. Never falls back to a hardcoded city list.
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _openMeteo = 'https://geocoding-api.open-meteo.com/v1/search';
  static const _nominatim = 'https://nominatim.openstreetmap.org/search';

  Future<List<GeocodedPlace>> search({
    required String query,
    required ApiClient apiClient,
    required String idToken,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final backend = await _searchBackend(apiClient, q, idToken);
    if (backend.isNotEmpty) return backend;

    final openMeteo = await _searchOpenMeteo(q);
    if (openMeteo.isNotEmpty) return openMeteo;

    return _searchNominatim(q);
  }

  Future<List<GeocodedPlace>> _searchBackend(
    ApiClient apiClient,
    String query,
    String idToken,
  ) async {
    try {
      final raw = await apiClient.searchLocations(query: query, idToken: idToken);
      return raw
          .whereType<Map>()
          .map((e) => GeocodedPlace.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.isValid)
          .toList();
    } catch (e) {
      debugPrint('Backend geocode search failed: $e');
      return const [];
    }
  }

  Future<List<GeocodedPlace>> _searchOpenMeteo(String query) async {
    try {
      final uri = Uri.parse(_openMeteo).replace(queryParameters: {
        'name': query,
        'count': '15',
        'language': 'en',
        'format': 'json',
      });
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];
      final body = jsonDecode(response.body);
      final results = body is Map ? body['results'] : null;
      if (results is! List) return const [];
      return results.whereType<Map>().map((item) {
        final name = (item['name'] ?? '').toString();
        final admin1 = (item['admin1'] ?? '').toString();
        final country = (item['country'] ?? '').toString();
        final parts = [name, admin1, country].where((p) => p.isNotEmpty).toList();
        return GeocodedPlace(
          name: name.isEmpty ? query : name,
          displayName: parts.isEmpty ? name : parts.join(', '),
          latitude: _asDouble(item['latitude']) ?? 0,
          longitude: _asDouble(item['longitude']) ?? 0,
          city: name,
          state: admin1.isEmpty ? null : admin1,
          country: country.isEmpty ? null : country,
        );
      }).where((p) => p.isValid).toList();
    } catch (e) {
      debugPrint('Open-Meteo geocode failed: $e');
      return const [];
    }
  }

  Future<List<GeocodedPlace>> _searchNominatim(String query) async {
    try {
      final uri = Uri.parse(_nominatim).replace(queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': '10',
        'accept-language': 'en',
      });
      final response = await _client.get(
        uri,
        headers: {'User-Agent': 'MausamPersonalAI/1.0 (contact@mausam.ai)'},
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];
      final raw = jsonDecode(response.body);
      if (raw is! List) return const [];
      return raw.whereType<Map>().map((item) {
        final display = (item['display_name'] ?? query).toString();
        final addr = item['address'] is Map ? Map<String, dynamic>.from(item['address'] as Map) : <String, dynamic>{};
        final name = (addr['city'] ??
                addr['town'] ??
                addr['village'] ??
                addr['suburb'] ??
                display.split(',').first)
            .toString();
        return GeocodedPlace(
          name: name,
          displayName: display,
          latitude: _asDouble(item['lat']) ?? 0,
          longitude: _asDouble(item['lon']) ?? 0,
          city: name,
          state: (addr['state'] ?? addr['region']) as String?,
          country: addr['country'] as String?,
        );
      }).where((p) => p.isValid).toList();
    } catch (e) {
      debugPrint('Nominatim geocode failed: $e');
      return const [];
    }
  }
}
