import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/core/models/admin_user.dart';
import 'package:seller_hub/data/datasources/admin_user_local_datasource.dart';
import 'package:seller_hub/data/datasources/admin_user_remote_datasource.dart';
import 'package:seller_hub/data/repositories/admin_user_repository_impl.dart';

class MockAdminUserRemoteDataSource implements AdminUserRemoteDataSource {
  AdminUserPageData? cannedData;
  bool throwError = false;

  @override
  Future<AdminUserPageData> getUsers({
    required String role,
    int page = 0,
    int size = 20,
    String? q,
    bool? blocked,
    bool? deleted,
  }) async {
    if (throwError) throw Exception('Network error');
    return cannedData ??
        AdminUserPageData(
          content: [
            AdminUser(
              id: 'user-1',
              phoneNumber: '9876543210',
              firstName: 'Test',
              lastName: 'User',
              role: role == 'SELLERS' ? 'ROLE_SELLER' : 'ROLE_CUSTOMER',
            ),
          ],
          page: page,
          size: size,
          totalElements: 1,
          totalPages: 1,
          first: true,
          last: true,
        );
  }

  @override
  Future<AdminUser> updateUserBlockedStatus({
    required String userId,
    required bool blocked,
  }) async {
    return AdminUser(
      id: userId,
      phoneNumber: '9876543210',
      firstName: 'Test',
      lastName: 'User',
      role: 'ROLE_CUSTOMER',
      isBlocked: blocked,
    );
  }

  @override
  Future<AdminUser> updateUserDeletedStatus({
    required String userId,
    required bool deleted,
  }) async {
    return AdminUser(
      id: userId,
      phoneNumber: '9876543210',
      firstName: 'Test',
      lastName: 'User',
      role: 'ROLE_CUSTOMER',
      isDeleted: deleted,
    );
  }

  @override
  Future<String> permanentlyDeleteUser({required String userId}) async {
    if (throwError) throw Exception('Network error');
    return userId;
  }
}

class MockAdminUserLocalDataSource implements AdminUserLocalDataSource {
  final Map<String, AdminUserPageData> cache = {};

  @override
  Future<AdminUserPageData?> getCachedUsers(String role) async {
    return cache[role.toUpperCase()];
  }

  @override
  Future<void> cacheUsers(String role, AdminUserPageData data) async {
    cache[role.toUpperCase()] = data;
  }

  @override
  Future<void> removeUserFromCache(String userId) async {
    for (final key in cache.keys.toList()) {
      final data = cache[key]!;
      final filtered = data.content.where((u) => u.id != userId).toList();
      cache[key] = AdminUserPageData(
        content: filtered,
        page: data.page,
        size: data.size,
        totalElements: filtered.length,
        totalPages: data.totalPages,
        first: data.first,
        last: data.last,
      );
    }
  }

  @override
  Future<void> clearCache() async {
    cache.clear();
  }
}

void main() {
  group('AdminUserRepository Tests', () {
    late MockAdminUserRemoteDataSource remote;
    late MockAdminUserLocalDataSource local;
    late AdminUserRepositoryImpl repository;

    setUp(() {
      remote = MockAdminUserRemoteDataSource();
      local = MockAdminUserLocalDataSource();
      repository = AdminUserRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );
    });

    test('returns cached users on default query when cache is available and forceRefresh is false', () async {
      final cached = AdminUserPageData(
        content: [
          const AdminUser(
            id: 'cached-user-1',
            phoneNumber: '8776543244',
            firstName: 'Vijay',
            lastName: 'Pal',
            role: 'ROLE_SELLER',
          ),
        ],
        page: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
        first: true,
        last: true,
      );

      await local.cacheUsers('SELLERS', cached);

      final result = await repository.getUsers(role: 'SELLERS', forceRefresh: false);

      expect(result.content.length, 1);
      expect(result.content.first.id, 'cached-user-1');
      expect(result.content.first.fullName, 'Vijay Pal');
    });

    test('fetches from remote when forceRefresh is true and updates local cache', () async {
      final result = await repository.getUsers(role: 'CUSTOMERS', forceRefresh: true);

      expect(result.content.length, 1);
      expect(result.content.first.role, 'ROLE_CUSTOMER');

      final cachedAfter = await local.getCachedUsers('CUSTOMERS');
      expect(cachedAfter, isNotNull);
      expect(cachedAfter!.content.first.id, 'user-1');
    });

    test('updateUserBlockedStatus delegates to remote data source', () async {
      final updated = await repository.updateUserBlockedStatus(userId: 'u123', blocked: true);

      expect(updated.id, 'u123');
      expect(updated.isBlocked, isTrue);
    });
  });
}
