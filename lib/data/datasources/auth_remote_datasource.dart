import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/api/auth_response_dto.dart';
import '../models/api/login_request_dto.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseDto> loginWithPassword({
    required String email,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<AuthResponseDto> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final requestDto = LoginRequestDto(email: email, password: password);

    final response = await _apiClient.post(
      ApiEndpoints.loginPassword,
      body: requestDto.toJson(),
    );

    final dto = AuthResponseDto.fromJson(response);
    if (!dto.success || dto.data == null) {
      throw ApiException(
        message: dto.message.isNotEmpty ? dto.message : 'Authentication failed',
        details: response,
      );
    }

    return dto;
  }
}
