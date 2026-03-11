import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'api_interceptor.dart';
import 'network_exceptions.dart';

/// Centralized HTTP client for all SwapTunes API communication.
///
/// Wraps the `http` package with interceptors, error parsing,
/// and standardized response handling.
class ApiClient {
  final http.Client _client;
  final ApiInterceptor _interceptor;

  ApiClient({required ApiInterceptor interceptor, http.Client? client})
    : _interceptor = interceptor,
      _client = client ?? http.Client();

  /// Builds the full URI from a relative endpoint path.
  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final fullUrl = '${ApiConstants.baseUrl}$path';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  // ── HTTP Methods ───────────────────────────────────────

  /// Performs a GET request to the given [path].
  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final headers = _interceptor.getHeaders();
    final uri = _buildUri(path, queryParams);

    debugPrint('[GET] $uri');
    final response = await _client.get(uri, headers: headers);
    return _handleResponse(response);
  }

  /// Performs a POST request to [path] with an optional JSON [body].
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final headers = _interceptor.getHeaders();
    final uri = _buildUri(path);

    debugPrint('[POST] $uri');
    final response = await _client.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// Performs a PATCH request to [path] with an optional JSON [body].
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final headers = _interceptor.getHeaders();
    final uri = _buildUri(path);

    debugPrint('[PATCH] $uri');
    final response = await _client.patch(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// Performs a DELETE request to [path] with an optional JSON [body].
  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) async {
    final headers = _interceptor.getHeaders();
    final uri = _buildUri(path);

    debugPrint('[DELETE] $uri');
    final response = await _client.delete(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  // ── Response Handling ──────────────────────────────────

  /// Parses the HTTP response and throws typed exceptions on failure.
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    // Parse backend error format: { "error": { "code": "...", "message": "..." } }
    String errorCode = 'UNKNOWN_ERROR';
    String errorMessage = 'An unexpected error occurred';

    try {
      final json = jsonDecode(response.body);
      if (json['error'] != null) {
        errorCode = json['error']['code'] ?? errorCode;
        errorMessage = json['error']['message'] ?? errorMessage;
      }
    } catch (_) {
      errorMessage = 'Failed to parse server response';
    }

    switch (statusCode) {
      case 401:
        throw UnauthorizedException(errorMessage);
      default:
        throw ApiException(
          code: errorCode,
          message: errorMessage,
          statusCode: statusCode,
        );
    }
  }
}
