import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/api_endpoints.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _client;
  final TokenStorage _tokenStorage;
  final String _baseUrl;
  final Duration _timeout;

  ApiClient({
    http.Client? client,
    TokenStorage? tokenStorage,
    String? baseUrl,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _baseUrl = baseUrl ?? ApiEndpoints.baseUrl,
        _timeout = timeout ?? const Duration(seconds: 60);

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$_baseUrl$cleanPath';
    return Uri.parse(fullUrl).replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }

  Future<Map<String, String>> _buildHeaders({bool requiresAuth = false}) async {
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

    return headers;
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'No internet connection or server unreachable: ${e.message}',
        details: e,
      );
    } on TimeoutException {
      throw const NetworkException(
        message: 'The server took too long to respond. The backend may be waking up from cold standby. Please try again.',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Network communication failure: ${e.message}',
        details: e,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error occurred: $e',
        details: e,
      );
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fileFieldName,
    required List<int> fileBytes,
    required String fileName,
    String? contentType,
    Map<String, String>? fields,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = _buildUri(path);
      final request = http.MultipartRequest('POST', uri);

      if (requiresAuth) {
        final token = await _tokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
      request.headers['Accept'] = 'application/json';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      MediaType? mediaType;
      if (contentType != null) {
        final parts = contentType.split('/');
        if (parts.length == 2) {
          mediaType = MediaType(parts[0], parts[1]);
        }
      }

      request.files.add(http.MultipartFile.fromBytes(
        fileFieldName,
        fileBytes,
        filename: fileName,
        contentType: mediaType,
      ));

      final streamedResponse = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'No internet connection or server unreachable: ${e.message}',
        details: e,
      );
    } on TimeoutException {
      throw const NetworkException(
        message: 'The server took too long to respond while uploading. Please try again.',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Network communication failure during upload: ${e.message}',
        details: e,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error during upload: $e',
        details: e,
      );
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .delete(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'No internet connection or server unreachable: ${e.message}',
        details: e,
      );
    } on TimeoutException {
      throw const NetworkException(
        message: 'The server took too long to respond. The backend may be waking up from cold standby. Please try again.',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Network communication failure: ${e.message}',
        details: e,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error occurred: $e',
        details: e,
      );
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'No internet connection or server unreachable: ${e.message}',
        details: e,
      );
    } on TimeoutException {
      throw const NetworkException(
        message: 'The server took too long to respond. The backend may be waking up from cold standby. Please try again.',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Network communication failure: ${e.message}',
        details: e,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error occurred: $e',
        details: e,
      );
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'No internet connection or server unreachable: ${e.message}',
        details: e,
      );
    } on TimeoutException {
      throw const NetworkException(
        message: 'The server took too long to respond. The backend may be waking up from cold standby. Please try again.',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Network communication failure: ${e.message}',
        details: e,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error occurred: $e',
        details: e,
      );
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
    int retries = 1,
  }) async {
    int attempts = 0;
    while (attempts <= retries) {
      attempts++;
      try {
        final uri = _buildUri(path, queryParameters);
        final headers = await _buildHeaders(requiresAuth: requiresAuth);

        final response = await _client.get(uri, headers: headers).timeout(_timeout);
        return _processResponse(response);
      } on SocketException catch (e) {
        if (attempts > retries) {
          throw NetworkException(
            message: 'No internet connection or server unreachable: ${e.message}',
            details: e,
          );
        }
        await Future.delayed(const Duration(milliseconds: 1500));
      } on TimeoutException {
        if (attempts > retries) {
          throw const NetworkException(
            message: 'Connection timed out. The cloud server may be waking up from standby. Please tap Retry.',
          );
        }
        await Future.delayed(const Duration(milliseconds: 1500));
      } on http.ClientException catch (e) {
        if (attempts > retries) {
          throw NetworkException(
            message: 'Network communication failure: ${e.message}',
            details: e,
          );
        }
        await Future.delayed(const Duration(milliseconds: 1500));
      } on ApiException {
        rethrow;
      } catch (e) {
        if (attempts > retries) {
          throw ApiException(
            message: 'Unexpected error occurred: $e',
            details: e,
          );
        }
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }
    throw const NetworkException(
      message: 'Failed to connect to server after retrying.',
    );
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    Map<String, dynamic> responseData;

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        responseData = decoded;
      } else {
        responseData = {'data': decoded};
      }
    } catch (e) {
      responseData = {
        'message': 'Failed to parse response body',
        'raw': response.body,
      };
    }

    final statusCode = response.statusCode;

    Map<String, String>? validationErrors;
    if (responseData['validationErrors'] is Map) {
      validationErrors = (responseData['validationErrors'] as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }

    if (statusCode >= 200 && statusCode < 300) {
      // Check if backend returned an explicit success=false
      if (responseData.containsKey('success') && responseData['success'] == false) {
        final message = responseData['message'] as String? ?? 'Operation failed';
        throw ApiException(
          message: message,
          statusCode: statusCode,
          validationErrors: validationErrors,
          details: responseData,
        );
      }
      return responseData;
    }

    final errorMessage = responseData['message'] as String? ??
        responseData['error'] as String? ??
        'Request failed with status $statusCode';

    if (statusCode == 400 && validationErrors != null && validationErrors.isNotEmpty) {
      throw ValidationException(
        message: errorMessage,
        validationErrors: validationErrors,
        statusCode: statusCode,
        details: responseData,
      );
    }

    if (statusCode == 401) {
      throw UnauthorizedException(
        message: errorMessage,
        validationErrors: validationErrors,
        details: responseData,
      );
    }

    if (statusCode >= 500) {
      throw ServerException(
        message: errorMessage,
        statusCode: statusCode,
        details: responseData,
      );
    }

    throw ApiException(
      message: errorMessage,
      statusCode: statusCode,
      validationErrors: validationErrors,
      details: responseData,
    );
  }
}
