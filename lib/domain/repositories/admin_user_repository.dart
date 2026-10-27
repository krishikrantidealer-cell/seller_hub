import '../../core/models/admin_user.dart';

abstract class AdminUserRepository {
  /// Fetches admin users for a given role ('SELLERS' or 'CUSTOMERS').
  /// Uses offline-first SWR caching if forceRefresh is false and page is 0.
  Future<AdminUserPageData> getUsers({
    required String role,
    int page = 0,
    int size = 20,
    String? q,
    bool? blocked,
    bool? deleted,
    bool forceRefresh = false,
  });

  /// Immediate local cache retrieval (0ms instant startup)
  Future<AdminUserPageData?> getCachedUsers(String role);

  /// Updates block status of a user
  Future<AdminUser> updateUserBlockedStatus({
    required String userId,
    required bool blocked,
  });

  /// Updates deletion status of a user
  Future<AdminUser> updateUserDeletedStatus({
    required String userId,
    required bool deleted,
  });
}
