import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

abstract class SellerAuthRemoteDataSource {
  Future<Map<String, dynamic>> loginWithPassword({required String email, required String password});
  Future<Map<String, dynamic>> sendEmailOtp(String email);
  Future<Map<String, dynamic>> verifyEmailOtp({required String email, required String otp});
  Future<Map<String, dynamic>> setupPassword(String newPassword);
  Future<Map<String, dynamic>> forgotPassword(String email);
  Future<Map<String, dynamic>> resetPassword({required String token, required String newPassword});
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
}

class SellerAuthRemoteDataSourceImpl implements SellerAuthRemoteDataSource {
  final ApiClient _client;

  SellerAuthRemoteDataSourceImpl(this._client);

  @override
  Future<Map<String, dynamic>> loginWithPassword({required String email, required String password}) async {
    final response = await _client.post(
      ApiEndpoints.sellerPasswordLogin,
      body: {
        'email': email,
        'password': password,
      },
    );
    return response is Map<String, dynamic> ? response : {};
  }

  @override
  Future<Map<String, dynamic>> sendEmailOtp(String email) async {
    final response = await _client.post(
      ApiEndpoints.sellerEmailOtpSend,
      body: {'email': email},
    );
    return response is Map<String, dynamic> ? response : {};
  }

  @override
  Future<Map<String, dynamic>> verifyEmailOtp({required String email, required String otp}) async {
    final response = await _client.post(
      ApiEndpoints.sellerEmailOtpVerify,
      body: {
        'email': email,
        'otp': otp,
      },
    );
    return response is Map<String, dynamic> ? response : {};
  }

  @override
  Future<Map<String, dynamic>> setupPassword(String newPassword) async {
    final response = await _client.post(
      ApiEndpoints.sellerPasswordSetup,
      body: {'newPassword': newPassword},
      requiresAuth: true,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _client.post(
      ApiEndpoints.sellerForgotPassword,
      body: {'email': email},
    );
    return response is Map<String, dynamic> ? response : {};
  }

  @override
  Future<Map<String, dynamic>> resetPassword({required String token, required String newPassword}) async {
    final response = await _client.post(
      ApiEndpoints.sellerPasswordReset,
      body: {
        'token': token,
        'newPassword': newPassword,
      },
    );
    return response is Map<String, dynamic> ? response : {};
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _client.post(
      ApiEndpoints.tokenRefresh,
      body: {'refreshToken': refreshToken},
    );
    return response is Map<String, dynamic> ? response : {};
  }
}
