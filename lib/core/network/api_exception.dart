class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, String>? validationErrors;
  final dynamic details;

  const ApiException({
    required this.message,
    this.statusCode,
    this.validationErrors,
    this.details,
  });

  @override
  String toString() =>
      'ApiException: $message (Status: $statusCode, Validation: $validationErrors)';
}

class NetworkException extends ApiException {
  const NetworkException({
    required super.message,
    super.details,
  }) : super(statusCode: null);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    required super.message,
    super.validationErrors,
    super.details,
  }) : super(statusCode: 401);
}

class ValidationException extends ApiException {
  const ValidationException({
    required super.message,
    required Map<String, String> super.validationErrors,
    super.statusCode = 400,
    super.details,
  });
}

class ServerException extends ApiException {
  const ServerException({
    required super.message,
    super.statusCode = 500,
    super.details,
  });
}
