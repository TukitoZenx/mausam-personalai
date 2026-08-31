import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? 'http://localhost:8080',
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

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
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to save user to backend: ${response.statusCode} ${response.body}');
    }
  }
}
