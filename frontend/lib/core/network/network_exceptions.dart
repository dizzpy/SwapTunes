/// Custom exception types matching the SwapTunes backend error format.
///
/// All API errors follow: `{ "error": { "code": "...", "message": "..." } }`
class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  const ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => 'ApiException($statusCode): [$code] $message';
}

/// Thrown when the device has no internet connectivity.
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when the server doesn't respond in time.
class TimeoutException implements Exception {
  final String message;
  const TimeoutException([this.message = 'Request timed out']);

  @override
  String toString() => 'TimeoutException: $message';
}

/// Thrown when the stored auth token is missing or expired.
class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Authentication required']);

  @override
  String toString() => 'UnauthorizedException: $message';
}
