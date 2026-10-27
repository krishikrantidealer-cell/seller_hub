import '../../core/models/admin_user.dart';
import '../../domain/repositories/admin_user_repository.dart';
import '../datasources/admin_user_local_datasource.dart';
import '../datasources/admin_user_remote_datasource.dart';

class AdminUserRepositoryImpl implements AdminUserRepository {
  final AdminUserRemoteDataSource remoteDataSource;
  final AdminUserLocalDataSource? localDataSource;

  AdminUserRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
  });

  @override
  Future<AdminUserPageData?> getCachedUsers(String role) async {
    return await localDataSource?.getCachedUsers(role);
  }

  @override
  Future<AdminUserPageData> getUsers({
    required String role,
    int page = 0,
    int size = 20,
    String? q,
    bool? blocked,
    bool? deleted,
    bool forceRefresh = false,
  }) async {
    final isDefaultQuery = page == 0 &&
        (q == null || q.trim().isEmpty) &&
        blocked == null &&
        deleted == null;

    if (!forceRefresh && isDefaultQuery && localDataSource != null) {
      final cached = await localDataSource!.getCachedUsers(role);
      if (cached != null && cached.content.isNotEmpty) {
        return cached;
      }
    }

    final remoteData = await remoteDataSource.getUsers(
      role: role,
      page: page,
      size: size,
      q: q,
      blocked: blocked,
      deleted: deleted,
    );

    if (isDefaultQuery && localDataSource != null) {
      await localDataSource!.cacheUsers(role, remoteData);
    }

    return remoteData;
  }

  @override
  Future<AdminUser> updateUserBlockedStatus({
    required String userId,
    required bool blocked,
  }) async {
    return await remoteDataSource.updateUserBlockedStatus(
      userId: userId,
      blocked: blocked,
    );
  }

  @override
  Future<AdminUser> updateUserDeletedStatus({
    required String userId,
    required bool deleted,
  }) async {
    return await remoteDataSource.updateUserDeletedStatus(
      userId: userId,
      deleted: deleted,
    );
  }
}
