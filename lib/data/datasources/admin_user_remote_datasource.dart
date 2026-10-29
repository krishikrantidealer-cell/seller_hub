import '../../core/constants/api_endpoints.dart';
import '../../core/models/admin_user.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

abstract class AdminUserRemoteDataSource {
  Future<AdminUserPageData> getUsers({
    required String role,
    int page = 0,
    int size = 20,
    String? q,
    bool? blocked,
    bool? deleted,
  });

  Future<AdminUser> updateUserBlockedStatus({
    required String userId,
    required bool blocked,
  });

  Future<AdminUser> updateUserDeletedStatus({
    required String userId,
    required bool deleted,
  });

  Future<String> permanentlyDeleteUser({
    required String userId,
  });
}

class AdminUserRemoteDataSourceImpl implements AdminUserRemoteDataSource {
  final ApiClient _apiClient;

  AdminUserRemoteDataSourceImpl(this._apiClient);

  @override
  Future<AdminUserPageData> getUsers({
    required String role,
    int page = 0,
    int size = 20,
    String? q,
    bool? blocked,
    bool? deleted,
  }) async {
    final queryParams = <String, dynamic>{
      'role': role,
      'page': page,
      'size': size,
    };
    if (q != null && q.trim().isNotEmpty) {
      queryParams['q'] = q.trim();
    }
    if (blocked != null) {
      queryParams['blocked'] = blocked;
    }
    if (deleted != null) {
      queryParams['deleted'] = deleted;
    }

    final response = await _apiClient.get(
      ApiEndpoints.adminUsers,
      queryParameters: queryParams,
      requiresAuth: true,
    );

    final success = response['success'] == true;
    final data = response['data'];

    if (!success || data == null || data is! Map<String, dynamic>) {
      final msg = response['message']?.toString() ?? 'Failed to retrieve admin users';
      throw ApiException(message: msg, details: response);
    }

    return AdminUserPageData.fromJson(data);
  }

  @override
  Future<AdminUser> updateUserBlockedStatus({
    required String userId,
    required bool blocked,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.adminUserBlock(userId),
      body: {'blocked': blocked},
      requiresAuth: true,
    );

    final success = response['success'] == true;
    final data = response['data'];

    if (!success || data == null || data is! Map<String, dynamic>) {
      final msg = response['message']?.toString() ?? 'Failed to update user blocked status';
      throw ApiException(message: msg, details: response);
    }

    return AdminUser.fromJson(data);
  }

  @override
  Future<AdminUser> updateUserDeletedStatus({
    required String userId,
    required bool deleted,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.adminUserDeletion(userId),
      body: {'deleted': deleted},
      requiresAuth: true,
    );

    final success = response['success'] == true;
    final data = response['data'];

    if (!success || data == null || data is! Map<String, dynamic>) {
      final msg = response['message']?.toString() ?? 'Failed to update user deleted status';
      throw ApiException(message: msg, details: response);
    }

    return AdminUser.fromJson(data);
  }

  @override
  Future<String> permanentlyDeleteUser({
    required String userId,
  }) async {
    final response = await _apiClient.delete(
      ApiEndpoints.adminUserPermanentDeletion(userId),
      requiresAuth: true,
    );

    final success = response['success'] == true;
    final data = response['data']?.toString() ?? userId;

    if (!success) {
      final msg = response['message']?.toString() ?? 'Failed to permanently delete user';
      throw ApiException(message: msg, details: response);
    }

    return data;
  }
}
