class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final List<String>? details;

  @override
  String toString() => message;
}

/// A message fit to show a student or admin for any error from a request:
/// the backend's own message plus its per-field validation details, or a
/// generic fallback for anything that is not an [ApiException].
String describeApiError(Object error) {
  if (error is! ApiException) return 'Something went wrong. Please try again.';
  final details = error.details;
  if (details == null || details.isEmpty) return error.message;
  return '${error.message}: ${details.join('; ')}';
}
