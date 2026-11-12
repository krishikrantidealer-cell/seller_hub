import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
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

  /// Permanently deletes a previously deactivated user account
  /// DELETE /api/v1/admin/users/{userId}/permanent
  Future<String> permanentlyDeleteUser(String userId);

  /// Creates a new customer account
  /// POST /api/v1/admin/users/customers
  Future<AdminUser> createCustomer(Map<String, dynamic> data);

  /// Creates a new seller account
  /// POST /api/v1/admin/users/sellers
  Future<AdminUser> createSeller(Map<String, dynamic> data);

  /// Uploads seller KYC documents to private storage
  /// POST /api/v1/admin/users/{userId}/kyc-documents
  Future<AdminUser> uploadKycDocuments({
    required String userId,
    List<PlatformFile>? licenceFiles,
    PlatformFile? gstCertificate,
    PlatformFile? panCard,
    PlatformFile? aadhaarCard,
    bool replaceLicenceFiles = false,
  });

  /// Approves or returns seller KYC for review
  /// PATCH /api/v1/admin/users/{userId}/kyc
  Future<AdminUser> reviewSellerKyc({
    required String userId,
    required bool approved,
  });

  /// Downloads a seller KYC document binary bytes from private storage
  /// GET /api/v1/admin/users/{userId}/kyc-documents/{documentType}/{index}
  Future<Uint8List> downloadKycDocument({
    required String userId,
    required String documentType,
    int index = 0,
  });
}
