import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../error/custom_exceptions.dart';

/// Basic HTTP client wrapper to centralize API calls.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final response = await _client.get(
      uri,
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    throw ApiException(
      'Request to ${uri.toString()} failed with status ${response.statusCode}',
      details: response.body,
    );
  }

  void dispose() {
    _client.close();
  }
}
