import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  Future<AdminUser> createCustomer(Map<String, dynamic> data);

  Future<AdminUser> createSeller(Map<String, dynamic> data);

  Future<AdminUser> uploadKycDocuments({
    required String userId,
    List<PlatformFile>? licenceFiles,
    PlatformFile? gstCertificate,
    PlatformFile? panCard,
    PlatformFile? aadhaarCard,
    bool replaceLicenceFiles = false,
  });

  Future<AdminUser> reviewSellerKyc({
    required String userId,
    required bool approved,
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

  @override
  Future<AdminUser> createCustomer(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiEndpoints.adminCreateCustomer,
      body: data,
      requiresAuth: true,
    );

    final success = response['success'] == true;
    final resData = response['data'];

    if (!success || resData == null || resData is! Map<String, dynamic>) {
      final msg = response['message']?.toString() ?? 'Failed to create customer account';
      throw ApiException(message: msg, details: response);
    }

    return AdminUser.fromJson(resData);
  }

  @override
  Future<AdminUser> createSeller(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiEndpoints.adminCreateSeller,
      body: data,
      requiresAuth: true,
    );

    final success = response['success'] == true;
    final resData = response['data'];

    if (!success || resData == null || resData is! Map<String, dynamic>) {
      final msg = response['message']?.toString() ?? 'Failed to create seller account';
      throw ApiException(message: msg, details: response);
    }

    return AdminUser.fromJson(resData);
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
    final multipartFiles = <http.MultipartFile>[];

    Future<void> addSingleFile(String fieldName, PlatformFile? file) async {
      if (file == null) return;
      List<int> bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      final ext = file.name.split('.').last.toLowerCase();
      MediaType mediaType;
      if (ext == 'pdf') {
        mediaType = MediaType('application', 'pdf');
      } else if (ext == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (ext == 'webp') {
        mediaType = MediaType('image', 'webp');
      } else {
        mediaType = MediaType('image', 'jpeg');
      }

      multipartFiles.add(http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: file.name,
        contentType: mediaType,
      ));
    }

    await addSingleFile('gstCertificate', gstCertificate);
    await addSingleFile('panCard', panCard);
    await addSingleFile('aadhaarCard', aadhaarCard);

    if (licenceFiles != null) {
      for (final lic in licenceFiles) {
        await addSingleFile('licenceImage', lic);
      }
    }

    if (multipartFiles.isEmpty) {
      throw const ApiException(message: 'Please select at least one document to upload');
    }

    final fields = <String, String>{
      'replaceLicenceFiles': replaceLicenceFiles ? 'true' : 'false',
    };

    final response = await _apiClient.postCustomMultipart(
      ApiEndpoints.adminSellerKycDocuments(userId),
      files: multipartFiles,
      fields: fields,
      requiresAuth: true,
    );

    final success = response['success'] == true;
    final resData = response['data'];

    if (!success || resData == null || resData is! Map<String, dynamic>) {
      final msg = response['message']?.toString() ?? 'Failed to upload KYC documents';
      throw ApiException(message: msg, details: response);
    }

    return AdminUser.fromJson(resData);
  }

  @override
  Future<AdminUser> reviewSellerKyc({
    required String userId,
    required bool approved,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.adminSellerKycReview(userId),
      body: {'approved': approved},
      requiresAuth: true,
    );

    final success = response['success'] == true;
    final resData = response['data'];

    if (!success || resData == null || resData is! Map<String, dynamic>) {
      final msg = response['message']?.toString() ?? 'Failed to review seller KYC';
      throw ApiException(message: msg, details: response);
    }

    return AdminUser.fromJson(resData);
  }
}
