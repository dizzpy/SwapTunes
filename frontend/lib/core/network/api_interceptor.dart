import '../services/storage_service.dart';

/// Handles injecting auth headers and logging for API requests.
///
/// Reads the stored JWT token from [StorageService] and attaches it
/// to every outgoing request as a Bearer token.
class ApiInterceptor {
  final StorageService _storage;

  ApiInterceptor(this._storage);

  /// Builds default headers for every API request.
  Map<String, String> getHeaders() {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = _storage.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final devGeminiKey = _storage.getDevGeminiKey();
    if (devGeminiKey != null && devGeminiKey.isNotEmpty) {
      headers['x-gemini-key'] = devGeminiKey;
    }

    return headers;
  }
}
