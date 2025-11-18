import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../constants/app_constants.dart';
import '../error/custom_exceptions.dart';

/// A lightweight wrapper around [HttpClient] to centralize networking concerns.
class ApiClient {
  ApiClient({HttpClient? httpClient}) : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  Future<Map<String, dynamic>> getJson(String path) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    late HttpClientRequest request;

    try {
      request = await _httpClient.getUrl(uri).timeout(AppConstants.defaultTimeout);
      final response = await request.close().timeout(AppConstants.defaultTimeout);
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NetworkException('Request failed', statusCode: response.statusCode);
      }

      return jsonDecode(body) as Map<String, dynamic>;
    } on TimeoutException catch (error) {
      throw NetworkException('Request timed out', cause: error);
    } on SocketException catch (error) {
      throw NetworkException('Network error occurred', cause: error);
    }
  }

  void close() {
    _httpClient.close(force: true);
  }
}
