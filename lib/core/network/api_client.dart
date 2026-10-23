import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _client;
  final TokenStorage _tokenStorage;
  static const Duration defaultTimeout = Duration(seconds: 25);

  ApiClient({
    http.Client? client,
    TokenStorage? tokenStorage,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? extraHeaders,
    bool requiresAuth = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  Future<dynamic> get(
    String url, {
    Map<String, String>? headers,
    bool requiresAuth = false,
  }) async {
    try {
      final requestHeaders = await _buildHeaders(
        extraHeaders: headers,
        requiresAuth: requiresAuth,
      );

      final response = await _client
          .get(Uri.parse(url), headers: requestHeaders)
          .timeout(defaultTimeout);

      return _processResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const NetworkException(message: 'Server request timed out. Please try again.');
    } catch (e) {
      if (kDebugMode) print('Seller Hub GET error: $e');
      throw NetworkException(message: 'Network connection failed: ${e.toString()}');
    }
  }

  Future<dynamic> post(
    String url, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = false,
  }) async {
    try {
      final requestHeaders = await _buildHeaders(
        extraHeaders: headers,
        requiresAuth: requiresAuth,
      );

      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await _client
          .post(
            Uri.parse(url),
            headers: requestHeaders,
            body: encodedBody,
          )
          .timeout(defaultTimeout);

      return _processResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const NetworkException(message: 'Server request timed out. Please try again.');
    } catch (e) {
      if (kDebugMode) print('Seller Hub POST error: $e');
      throw NetworkException(message: 'Network connection failed: ${e.toString()}');
    }
  }

  Future<dynamic> put(
    String url, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = false,
  }) async {
    try {
      final requestHeaders = await _buildHeaders(
        extraHeaders: headers,
        requiresAuth: requiresAuth,
      );

      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await _client
          .put(
            Uri.parse(url),
            headers: requestHeaders,
            body: encodedBody,
          )
          .timeout(defaultTimeout);

      return _processResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const NetworkException(message: 'Server request timed out. Please try again.');
    } catch (e) {
      if (kDebugMode) print('Seller Hub PUT error: $e');
      throw NetworkException(message: 'Network connection failed: ${e.toString()}');
    }
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (statusCode >= 200 && statusCode < 300) {
      return responseBody;
    }

    final message = (responseBody is Map && responseBody['message'] != null)
        ? responseBody['message'].toString()
        : 'Request failed with status $statusCode';

    switch (statusCode) {
      case 400:
        throw ValidationException(
          message: message,
          statusCode: 400,
          errors: responseBody is Map ? responseBody['validationErrors'] : null,
        );
      case 401:
        throw UnauthorizedException(message: message, statusCode: 401);
      case 403:
        throw ForbiddenException(message: message, statusCode: 403);
      case 404:
        throw NotFoundException(message: message, statusCode: 404);
      case 500:
      default:
        throw ServerException(message: message, statusCode: statusCode, details: responseBody);
    }
  }
}
