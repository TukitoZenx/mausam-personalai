import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ??
            (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
                ? 'http://10.0.2.2:8000'
                : 'http://localhost:8000'),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> getMe({required String idToken}) async {
    final url = Uri.parse('$baseUrl/users/me');
    final response = await _client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch user profile: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>> postUser({
    required String idToken,
    required String email,
    String? personaType,
    bool? notificationsEnabled,
    bool? locationAccess,
    String? persona,
    String? interests,
  }) async {
    final url = Uri.parse('$baseUrl/users/me');
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'email': email,
        if (personaType != null) 'persona_type': personaType,
        if (notificationsEnabled != null) 'notifications_enabled': notificationsEnabled,
        if (locationAccess != null) 'location_access': locationAccess,
        if (persona != null) 'persona': persona,
        if (interests != null) 'interests': interests,
      }),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to save user to backend: ${response.statusCode} ${response.body}');
    }
  }

  // --- Location Endpoints ---

  Future<Map<String, dynamic>> fetchCurrentLocation({
    required double lat,
    required double lon,
    required String idToken,
  }) async {
    final url = Uri.parse('$baseUrl/locations/current?lat=$lat&lon=$lon');
    final response = await _client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to reverse geocode location: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> fetchSavedLocations({required String idToken}) async {
    final url = Uri.parse('$baseUrl/locations/saved');
    final response = await _client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to fetch saved locations: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> saveLocation({
    required String name,
    required double latitude,
    required double longitude,
    required String idToken,
  }) async {
    final url = Uri.parse('$baseUrl/locations/saved');
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
      }),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to save destination: ${response.statusCode}');
    }
  }

  Future<void> deleteSavedLocation({
    required String id,
    required String idToken,
  }) async {
    final url = Uri.parse('$baseUrl/locations/saved/$id');
    final response = await _client.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete saved location: ${response.statusCode}');
    }
  }
}
