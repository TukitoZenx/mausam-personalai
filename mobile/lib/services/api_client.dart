import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/personalized_home_response.dart';

class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000',
            ),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  List<String> get _candidateHosts => [
        ...{
          baseUrl,
          'http://10.0.2.2:8000',
          'http://127.0.0.1:8000',
          'http://localhost:8000',
        }
      ];

  // --- Personalization Endpoints ---

  Future<PersonalizedHomeResponse> fetchPersonalizedHome({
    required double lat,
    required double lon,
    String? savedLocationId,
    int? hour,
    String? tz,
    required String idToken,
  }) async {
    final queryParams = <String, String>{
      'lat': lat.toString(),
      'lon': lon.toString(),
      'hour': (hour ?? DateTime.now().hour).toString(),
      'tz': tz ?? DateTime.now().timeZoneName,
    };
    if (savedLocationId != null && savedLocationId.isNotEmpty) {
      queryParams['saved_location_id'] = savedLocationId;
    }

    Object? lastError;
    for (final host in _candidateHosts) {
      try {
        final uri = Uri.parse('$host/personalization/home').replace(queryParameters: queryParams);
        final response = await _client.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final bodyMap = jsonDecode(response.body) as Map<String, dynamic>;
          return PersonalizedHomeResponse.fromJson(bodyMap);
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Failed to fetch personalized home feed: $lastError');
  }

  Future<void> recordInteraction({
    required String cardType,
    required String action,
    String? cardId,
    String? timestamp,
    required String idToken,
  }) async {
    for (final host in _candidateHosts) {
      try {
        final uri = Uri.parse('$host/personalization/interactions');
        final response = await _client.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'card_type': cardType,
            'action': action,
            'card_id': cardId ?? cardType,
            'action_type': action,
            'timestamp': timestamp ?? DateTime.now().toIso8601String(),
          }),
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) break;
      } catch (e) {
        debugPrint('Interaction POST failed on host $host: $e');
      }
    }
  }

  Future<Map<String, dynamic>> getMe({required String idToken}) async {
    Object? lastError;
    for (final host in _candidateHosts) {
      try {
        final url = Uri.parse('$host/users/me');
        final response = await _client.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Failed to fetch user profile: $lastError');
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
    Object? lastError;
    for (final host in _candidateHosts) {
      try {
        final url = Uri.parse('$host/users/me');
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
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Failed to save user to backend: $lastError');
  }

  // --- Location Endpoints ---

  Future<Map<String, dynamic>> fetchCurrentLocation({
    required double lat,
    required double lon,
    required String idToken,
  }) async {
    Object? lastError;
    for (final host in _candidateHosts) {
      try {
        final url = Uri.parse('$host/locations/current?lat=$lat&lon=$lon');
        final response = await _client.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Failed to reverse geocode location: $lastError');
  }

  Future<List<dynamic>> fetchSavedLocations({required String idToken}) async {
    Object? lastError;
    for (final host in _candidateHosts) {
      try {
        final url = Uri.parse('$host/locations/saved');
        final response = await _client.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as List<dynamic>;
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Failed to fetch saved locations: $lastError');
  }

  Future<Map<String, dynamic>> saveLocation({
    required String name,
    required double latitude,
    required double longitude,
    required String idToken,
  }) async {
    Object? lastError;
    for (final host in _candidateHosts) {
      try {
        final url = Uri.parse('$host/locations/saved');
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
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Failed to save destination: $lastError');
  }

  Future<void> deleteSavedLocation({
    required String id,
    required String idToken,
  }) async {
    Object? lastError;
    for (final host in _candidateHosts) {
      try {
        final url = Uri.parse('$host/locations/saved/$id');
        final response = await _client.delete(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 204 || response.statusCode == 200) return;
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Failed to delete saved location: $lastError');
  }

  Future<Map<String, dynamic>> fetchWeatherForecast({
    required double lat,
    required double lon,
    required String idToken,
  }) async {
    Object? lastError;
    for (final host in _candidateHosts) {
      try {
        final url = Uri.parse('$host/weather/forecast?lat=$lat&lon=$lon');
        final response = await _client.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
        ).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Failed to fetch weather forecast: $lastError');
  }

  Future<Map<String, dynamic>> fetchCurrentAqi({
    required double lat,
    required double lon,
    required String idToken,
  }) async {
    Object? lastError;
    for (final host in _candidateHosts) {
      try {
        final url = Uri.parse('$host/aqi/current?lat=$lat&lon=$lon');
        final response = await _client.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
        ).timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Failed to fetch AQI: $lastError');
  }
}
