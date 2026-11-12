import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/admin_user.dart';

abstract class AdminUserEvent extends Equatable {
  const AdminUserEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAdminUsers extends AdminUserEvent {
  final bool forceRefresh;
  const InitializeAdminUsers({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class FetchAdminUsers extends AdminUserEvent {
  final int page;
  final int size;
  final String? query;
  final bool? blocked;
  final bool? deleted;
  final bool isBackground;

  const FetchAdminUsers({
    this.page = 0,
    this.size = 20,
    this.query,
    this.blocked,
    this.deleted,
    this.isBackground = false,
  });

  @override
  List<Object?> get props => [page, size, query, blocked, deleted, isBackground];
}

class LoadMoreAdminUsers extends AdminUserEvent {
  const LoadMoreAdminUsers();
}

class SearchAdminUsers extends AdminUserEvent {
  final String query;
  const SearchAdminUsers(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterAdminUsersStatus extends AdminUserEvent {
  final String status;
  const FilterAdminUsersStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class ToggleBlockAdminUser extends AdminUserEvent {
  final String userId;
  final bool blocked;

  const ToggleBlockAdminUser({
    required this.userId,
    required this.blocked,
  });

  @override
  List<Object?> get props => [userId, blocked];
}

class ToggleDeleteAdminUser extends AdminUserEvent {
  final String userId;
  final bool deleted;

  const ToggleDeleteAdminUser({
    required this.userId,
    required this.deleted,
  });

  @override
  List<Object?> get props => [userId, deleted];
}

class PermanentlyDeleteAdminUser extends AdminUserEvent {
  final String userId;

  const PermanentlyDeleteAdminUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateAdminUser extends AdminUserEvent {
  final Map<String, dynamic> userData;
  final void Function(AdminUser user)? onSuccess;

  const CreateAdminUser({
    required this.userData,
    this.onSuccess,
  });

  @override
  List<Object?> get props => [userData];
}

class UpdateLocalAdminUser extends AdminUserEvent {
  final AdminUser user;
  const UpdateLocalAdminUser(this.user);

  @override
  List<Object?> get props => [user];
}

class UploadAdminUserKycDocuments extends AdminUserEvent {
  final String userId;
  final List<PlatformFile>? licenceFiles;
  final PlatformFile? gstCertificate;
  final PlatformFile? panCard;
  final PlatformFile? aadhaarCard;
  final bool replaceLicenceFiles;
  final void Function(AdminUser user)? onSuccess;
  final void Function(String error)? onError;

  const UploadAdminUserKycDocuments({
    required this.userId,
    this.licenceFiles,
    this.gstCertificate,
    this.panCard,
    this.aadhaarCard,
    this.replaceLicenceFiles = false,
    this.onSuccess,
    this.onError,
  });

  @override
  List<Object?> get props => [
        userId,
        licenceFiles,
        gstCertificate,
        panCard,
        aadhaarCard,
        replaceLicenceFiles,
      ];
}

class ReviewAdminUserKyc extends AdminUserEvent {
  final String userId;
  final bool approved;
  final void Function(AdminUser user)? onSuccess;
  final void Function(String error)? onError;

  const ReviewAdminUserKyc({
    required this.userId,
    required this.approved,
    this.onSuccess,
    this.onError,
  });

  @override
  List<Object?> get props => [userId, approved];
}
