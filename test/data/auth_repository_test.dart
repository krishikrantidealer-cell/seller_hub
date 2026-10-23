import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seller_hub/core/network/api_client.dart';
import 'package:seller_hub/core/network/api_exception.dart';
import 'package:seller_hub/core/storage/token_storage.dart';
import 'package:seller_hub/data/datasources/auth_remote_datasource.dart';
import 'package:seller_hub/data/repositories/auth_repository_impl.dart';

void main() {
  const sampleSuccessResponse = {
    "success": true,
    "message": "Authentication successful",
    "data": {
      "accessToken":
          "eyJhbGciOiJIUzM4NCJ9.eyJzdWIiOiI5ODc2NTQzNjY4IiwidXNlcklkIjoiNmFiNGFlNjkyMjAzM2YxNjcwNTgyYmRiIiwicm9sZSI6IlJPTEVfQURNSU4iLCJ0b2tlblR5cGUiOiJBQ0NFU1MiLCJpYXQiOjE3OTI3NDg5NzEsImV4cCI6MTc5MjgzNTM3MX0.DTfyiYsCbE86q1fASDbHdvAnxGFN76YTycllbOifKHhniVCGWemUt_Kjy64mIF3h",
      "refreshToken":
          "eyJhbGciOiJIUzM4NCJ9.eyJzdWIiOiI5ODc2NTQzNjY4IiwidXNlcklkIjoiNmFiNGFlNjkyMjAzM2YxNjcwNTgyYmRiIiwidG9rZW5UeXBlIjoiUkVGUkVTSCIsImlhdCI6MTc5Mjc0ODk3MSwiZXhwIjoxNzkzMzUzNzcxfQ.WjVU3ODwAM2T2QwshTc5yVKjPIny3etpw4bhm178g6vmL6v_J9lGUk_1Cfaub8U_",
      "tokenType": "Bearer",
      "expiresInMs": 86400000,
      "userId": "6ab4ae6922033f1670582bdb",
      "phoneNumber": "9876543668",
      "role": "ROLE_ADMIN",
      "isProfileComplete": true
    },
    "timestamp": "2026-10-23T09:49:31.843224715"
  };

  group('AuthRemoteDataSourceImpl', () {
    test('loginWithPassword successfully parses exact admin response payload', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/password/login');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'admin1email@example.com');
        expect(body['password'], 'Admin!Pass123');

        return http.Response(
          jsonEncode(sampleSuccessResponse),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:8080');
      final dataSource = AuthRemoteDataSourceImpl(apiClient);

      final result = await dataSource.loginWithPassword(
        email: 'admin1email@example.com',
        password: 'Admin!Pass123',
      );

      expect(result.success, isTrue);
      expect(result.message, 'Authentication successful');
      expect(result.data, isNotNull);
      expect(result.data!.userId, '6ab4ae6922033f1670582bdb');
      expect(result.data!.role, 'ROLE_ADMIN');
      expect(result.data!.phoneNumber, '9876543668');
      expect(result.data!.tokenType, 'Bearer');
      expect(result.data!.isProfileComplete, isTrue);
    });

    test('loginWithPassword throws ApiException on invalid credentials', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            "success": false,
            "message": "Invalid email or password",
          }),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:8080');
      final dataSource = AuthRemoteDataSourceImpl(apiClient);

      expect(
        () => dataSource.loginWithPassword(
          email: 'admin1email@example.com',
          password: 'WrongPassword',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('AuthRepositoryImpl', () {
    test('loginWithPassword persists session to TokenStorage and returns AuthSession', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final tokenStorage = TokenStorage(prefs: prefs);

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode(sampleSuccessResponse),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(client: mockClient, tokenStorage: tokenStorage);
      final remoteDataSource = AuthRemoteDataSourceImpl(apiClient);
      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        tokenStorage: tokenStorage,
      );

      final session = await repository.loginWithPassword(
        email: 'admin1email@example.com',
        password: 'Admin!Pass123',
      );

      expect(session.userId, '6ab4ae6922033f1670582bdb');
      expect(session.role, 'ROLE_ADMIN');
      expect(session.isAdmin, isTrue);
      expect(session.phoneNumber, '9876543668');

      // Verify persisted storage
      expect(await tokenStorage.getAccessToken(), session.accessToken);
      expect(await tokenStorage.getUserId(), '6ab4ae6922033f1670582bdb');
      expect(await tokenStorage.getRole(), 'ROLE_ADMIN');

      // Verify checkAuthStatus retrieves it
      final retrievedSession = await repository.checkAuthStatus();
      expect(retrievedSession, isNotNull);
      expect(retrievedSession!.userId, '6ab4ae6922033f1670582bdb');

      // Verify logout clears it
      await repository.logout();
      expect(await tokenStorage.hasValidToken(), isFalse);
      expect(await repository.checkAuthStatus(), isNull);
    });
  });
}
