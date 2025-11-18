/// Base application exception for typed error handling.
class AppException implements Exception {
  AppException(this.message, {this.details});

  final String message;
  final Object? details;

  @override
  String toString() => 'AppException(message: $message, details: $details)';
}

/// Thrown when an operation fails due to network connectivity issues.
class NetworkException extends AppException {
  NetworkException(String message, {Object? details})
      : super(message, details: details);
}

/// Thrown when a request receives an invalid or unexpected response.
class ApiException extends AppException {
  ApiException(String message, {Object? details})
      : super(message, details: details);
}
