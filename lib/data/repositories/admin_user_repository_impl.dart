import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
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

  @override
  Future<String> permanentlyDeleteUser(String userId) async {
    final result = await remoteDataSource.permanentlyDeleteUser(userId: userId);
    await localDataSource?.removeUserFromCache(userId);
    return result;
  }

  @override
  Future<AdminUser> createCustomer(Map<String, dynamic> data) async {
    return await remoteDataSource.createCustomer(data);
  }

  @override
  Future<AdminUser> createSeller(Map<String, dynamic> data) async {
    return await remoteDataSource.createSeller(data);
  }

  @override
  Future<AdminUser> uploadKycDocuments({
    required String userId,
    List<PlatformFile>? licenceFiles,
    PlatformFile? gstCertificate,
    PlatformFile? panCard,
    PlatformFile? aadhaarCard,
    bool replaceLicenceFiles = false,
  }) async {
    final updated = await remoteDataSource.uploadKycDocuments(
      userId: userId,
      licenceFiles: licenceFiles,
      gstCertificate: gstCertificate,
      panCard: panCard,
      aadhaarCard: aadhaarCard,
      replaceLicenceFiles: replaceLicenceFiles,
    );
    return updated;
  }

  @override
  Future<AdminUser> reviewSellerKyc({
    required String userId,
    required bool approved,
  }) async {
    final updated = await remoteDataSource.reviewSellerKyc(
      userId: userId,
      approved: approved,
    );
    return updated;
  }

  @override
  Future<Uint8List> downloadKycDocument({
    required String userId,
    required String documentType,
    int index = 0,
  }) async {
    return await remoteDataSource.downloadKycDocument(
      userId: userId,
      documentType: documentType,
      index: index,
    );
  }
}
