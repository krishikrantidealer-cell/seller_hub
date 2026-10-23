class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
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
    super.details,
  }) : super(statusCode: 401);
}

class ServerException extends ApiException {
  const ServerException({
    required super.message,
    super.statusCode = 500,
    super.details,
  });
}
