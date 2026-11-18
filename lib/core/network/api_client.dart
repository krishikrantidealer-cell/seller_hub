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
  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();
  Completer<bool>? _refreshCompleter;

  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

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
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final uri = Uri.parse(path);
      if (queryParameters == null || queryParameters.isEmpty) return uri;
      final mergedParams = Map<String, String>.from(uri.queryParameters);
      queryParameters.forEach((key, value) {
        if (value != null) mergedParams[key] = value.toString();
      });
      return uri.replace(queryParameters: mergedParams);
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$_baseUrl$cleanPath';
    return Uri.parse(fullUrl).replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null ||
          refreshToken.isEmpty ||
          TokenStorage.isJwtExpired(refreshToken)) {
        await _expireSession();
        completer.complete(false);
        return false;
      }

      final uri = _buildUri(ApiEndpoints.refreshToken);
      final response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final payload = (decoded is Map<String, dynamic> && decoded['data'] is Map)
            ? Map<String, dynamic>.from(decoded['data'] as Map)
            : (decoded is Map<String, dynamic> ? decoded : <String, dynamic>{});
        final newAccess = payload['accessToken'] as String? ?? '';
        final newRefresh = payload['refreshToken'] as String? ?? refreshToken;
        if (newAccess.isNotEmpty) {
          final existingUserId = await _tokenStorage.getUserId() ?? '';
          final existingRole = await _tokenStorage.getRole() ?? 'ROLE_ADMIN';
          final existingPhone = await _tokenStorage.getPhoneNumber();
          await _tokenStorage.saveSession(
            accessToken: newAccess,
            refreshToken: newRefresh,
            userId: (payload['userId'] as String?)?.isNotEmpty == true
                ? payload['userId'] as String
                : existingUserId,
            role: (payload['role'] as String?)?.isNotEmpty == true
                ? payload['role'] as String
                : existingRole,
            phoneNumber: payload['phoneNumber'] as String? ?? existingPhone,
          );
          completer.complete(true);
          return true;
        }
      }

      await _expireSession();
      completer.complete(false);
      return false;
    } catch (_) {
      await _expireSession();
      if (!completer.isCompleted) completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _expireSession() async {
    await _tokenStorage.clearSession();
    if (!_sessionExpiredController.isClosed) {
      _sessionExpiredController.add(null);
    }
  }

  Future<http.Response> _sendWithAuthRetry(
    Future<http.Response> Function() send, {
    required bool requiresAuth,
    String? path,
  }) async {
    var response = await send();
    if (response.statusCode == 401 &&
        requiresAuth &&
        path != ApiEndpoints.refreshToken) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await send();
      }
    }
    return response;
  }

  Future<Map<String, String>> _buildHeaders({bool requiresAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      var token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty && TokenStorage.isJwtExpired(token)) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          token = await _tokenStorage.getAccessToken();
        } else {
          token = null;
        }
      }
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        throw const UnauthorizedException(
          message: 'Session expired. Please sign in again.',
        );
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
      final response = await _sendWithAuthRetry(
        () async {
          final headers = await _buildHeaders(requiresAuth: requiresAuth);
          return _client
              .post(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
        },
        requiresAuth: requiresAuth,
        path: path,
      );

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
        } else {
          throw const UnauthorizedException(
            message: 'Full authentication is required to access this resource. Please sign in.',
          );
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

  Future<Map<String, dynamic>> postMultipartFiles(
    String path, {
    required String fileFieldName,
    required List<List<int>> filesBytes,
    required List<String> fileNames,
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
        } else {
          throw const UnauthorizedException(
            message: 'Full authentication is required to access this resource. Please sign in.',
          );
        }
      }
      request.headers['Accept'] = 'application/json';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      for (int i = 0; i < filesBytes.length; i++) {
        final name = i < fileNames.length ? fileNames[i] : 'image_$i.jpg';
        final ext = name.split('.').last.toLowerCase();
        final mimeType = (ext == 'png') ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
        final parts = mimeType.split('/');
        request.files.add(http.MultipartFile.fromBytes(
          fileFieldName,
          filesBytes[i],
          filename: name,
          contentType: MediaType(parts[0], parts[1]),
        ));
      }

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

  Future<Map<String, dynamic>> postCustomMultipart(
    String path, {
    required List<http.MultipartFile> files,
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
        } else {
          throw const UnauthorizedException(
            message: 'Full authentication is required to access this resource. Please sign in.',
          );
        }
      }
      request.headers['Accept'] = 'application/json';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      request.files.addAll(files);

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
      final response = await _sendWithAuthRetry(
        () async {
          final headers = await _buildHeaders(requiresAuth: requiresAuth);
          return _client
              .delete(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
        },
        requiresAuth: requiresAuth,
        path: path,
      );

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
      final response = await _sendWithAuthRetry(
        () async {
          final headers = await _buildHeaders(requiresAuth: requiresAuth);
          return _client
              .patch(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
        },
        requiresAuth: requiresAuth,
        path: path,
      );

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
      final response = await _sendWithAuthRetry(
        () async {
          final headers = await _buildHeaders(requiresAuth: requiresAuth);
          return _client
              .put(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
        },
        requiresAuth: requiresAuth,
        path: path,
      );

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

  Future<http.Response> getRaw(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path, queryParameters);
    return _sendWithAuthRetry(
      () async {
        final headers = await _buildHeaders(requiresAuth: requiresAuth);
        return _client.get(uri, headers: headers).timeout(_timeout);
      },
      requiresAuth: requiresAuth,
      path: path,
    );
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
        final response = await _sendWithAuthRetry(
          () async {
            final headers = await _buildHeaders(requiresAuth: requiresAuth);
            return _client.get(uri, headers: headers).timeout(_timeout);
          },
          requiresAuth: requiresAuth,
          path: path,
        );
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
