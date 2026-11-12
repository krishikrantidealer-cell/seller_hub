import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/core/models/admin_user.dart';
import 'package:seller_hub/domain/repositories/admin_user_repository.dart';
import 'package:seller_hub/logic/admin_user/admin_user_event.dart';
import 'package:seller_hub/logic/admin_user/admin_user_state.dart';
import 'package:seller_hub/logic/admin_user/customer_bloc.dart';
import 'package:seller_hub/logic/admin_user/seller_bloc.dart';

class FakeAdminUserRepository implements AdminUserRepository {
  AdminUserPageData? cachedSellers;
  AdminUserPageData? cachedCustomers;

  List<AdminUser> sellersList = [
    const AdminUser(
      id: '6ab62c7f4aec9f42cea26a49',
      phoneNumber: '8776543244',
      email: 'seller1@example.com',
      firstName: 'Vijay',
      lastName: 'Pal',
      role: 'ROLE_SELLER',
      isVerified: true,
      isProfileComplete: true,
      address: UserAddress(
        cityTehsil: 'Indore',
        state: 'Madhya Pradesh',
        pincode: '452001',
      ),
    ),
  ];

  List<AdminUser> customersList = [
    const AdminUser(
      id: '6ab6248acf88a4428f9b1e26',
      phoneNumber: '9876543244',
      firstName: 'Aashutosh',
      lastName: 'Shrivastava',
      role: 'ROLE_CUSTOMER',
      isVerified: true,
      isProfileComplete: true,
      address: UserAddress(
        villageArea: 'Plot 42, Kisan Nagar',
        cityTehsil: 'Indore',
        state: 'Madhya Pradesh',
        pincode: '452001',
      ),
    ),
  ];

  @override
  Future<AdminUserPageData?> getCachedUsers(String role) async {
    return role.toUpperCase() == 'SELLERS' ? cachedSellers : cachedCustomers;
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
    final list = role.toUpperCase() == 'SELLERS' ? sellersList : customersList;
    return AdminUserPageData(
      content: list,
      page: page,
      size: size,
      totalElements: list.length,
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
      phoneNumber: '9876543244',
      firstName: 'Updated',
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
      phoneNumber: '9876543244',
      firstName: 'Updated',
      lastName: 'User',
      role: 'ROLE_CUSTOMER',
      isDeleted: deleted,
    );
  }

  @override
  Future<String> permanentlyDeleteUser(String userId) async {
    sellersList.removeWhere((u) => u.id == userId);
    customersList.removeWhere((u) => u.id == userId);
    return userId;
  }

  @override
  Future<AdminUser> createCustomer(Map<String, dynamic> data) async {
    final newUser = AdminUser(
      id: 'cust-${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: data['phoneNumber']?.toString() ?? '9876543210',
      firstName: data['firstName']?.toString() ?? 'New',
      lastName: data['lastName']?.toString() ?? 'Customer',
      role: 'ROLE_CUSTOMER',
    );
    customersList.insert(0, newUser);
    return newUser;
  }

  @override
  Future<AdminUser> createSeller(Map<String, dynamic> data) async {
    final newUser = AdminUser(
      id: 'seller-${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: data['phoneNumber']?.toString() ?? '9876543210',
      firstName: data['firstName']?.toString() ?? 'New',
      lastName: data['lastName']?.toString() ?? 'Seller',
      shopName: data['shopName']?.toString() ?? 'New Store',
      role: 'ROLE_SELLER',
    );
    sellersList.insert(0, newUser);
    return newUser;
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
    final idx = sellersList.indexWhere((u) => u.id == userId);
    final current = idx >= 0
        ? sellersList[idx]
        : AdminUser(id: userId, phoneNumber: '9876543210', role: 'ROLE_SELLER');
    final updated = current.copyWith(
      gstCertificate: gstCertificate != null ? 'gs://bucket/kyc/gst.pdf' : current.gstCertificate,
      panCard: panCard != null ? 'gs://bucket/kyc/pan.pdf' : current.panCard,
      aadhaarCard: aadhaarCard != null ? 'gs://bucket/kyc/aadhaar.pdf' : current.aadhaarCard,
      licenceImages: licenceFiles != null ? ['gs://bucket/kyc/lic.pdf'] : current.licenceImages,
    );
    if (idx >= 0) sellersList[idx] = updated;
    return updated;
  }

  @override
  Future<AdminUser> reviewSellerKyc({
    required String userId,
    required bool approved,
  }) async {
    final idx = sellersList.indexWhere((u) => u.id == userId);
    final current = idx >= 0
        ? sellersList[idx]
        : AdminUser(id: userId, phoneNumber: '9876543210', role: 'ROLE_SELLER');
    final updated = current.copyWith(
      kycStatus: approved ? 'APPROVED' : null,
      isKycComplete: approved,
    );
    if (idx >= 0) sellersList[idx] = updated;
    return updated;
  }
}

void main() {
  group('CustomerBloc Tests', () {
    late FakeAdminUserRepository repository;
    late CustomerBloc bloc;

    setUp(() {
      repository = FakeAdminUserRepository();
      bloc = CustomerBloc(repository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state has AdminUserStatus.initial', () {
      expect(bloc.state.status, AdminUserStatus.initial);
      expect(bloc.state.users, isEmpty);
    });

    test('InitializeAdminUsers loads remote customers and emits loaded state', () async {
      bloc.add(const InitializeAdminUsers());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminUserState>((state) =>
              state.status == AdminUserStatus.loaded &&
              state.users.isNotEmpty &&
              state.users.first.firstName == 'Aashutosh' &&
              state.users.first.role == 'ROLE_CUSTOMER'),
        ),
      );
    });

    test('SearchAdminUsers updates searchQuery and filters user list', () async {
      bloc.add(const InitializeAdminUsers());
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<AdminUserState>((s) => s.status == AdminUserStatus.loaded)),
      );

      bloc.add(const SearchAdminUsers('Aashutosh'));
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<AdminUserState>((s) => s.searchQuery == 'Aashutosh')),
      );
      expect(bloc.state.filteredUsers.length, 1);

      bloc.add(const SearchAdminUsers('NonExistent'));
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<AdminUserState>((s) => s.searchQuery == 'NonExistent')),
      );
      expect(bloc.state.filteredUsers, isEmpty);
    });

    test('ToggleBlockAdminUser updates user blocked status and shows success message', () async {
      bloc.add(const InitializeAdminUsers());
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<AdminUserState>((s) => s.status == AdminUserStatus.loaded)),
      );

      bloc.add(const ToggleBlockAdminUser(
        userId: '6ab6248acf88a4428f9b1e26',
        blocked: true,
      ));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminUserState>((s) =>
              s.actionSuccessMessage == 'User blocked successfully' &&
              s.users.first.isBlocked == true),
        ),
      );
    });

    test('ToggleDeleteAdminUser updates customer deleted status and shows success message', () async {
      bloc.add(const InitializeAdminUsers());
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<AdminUserState>((s) => s.status == AdminUserStatus.loaded)),
      );

      bloc.add(const ToggleDeleteAdminUser(
        userId: '6ab6248acf88a4428f9b1e26',
        deleted: true,
      ));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminUserState>((s) =>
              s.actionSuccessMessage == 'User deactivated successfully' &&
              s.users.first.isDeleted == true),
        ),
      );
    });

    test('PermanentlyDeleteAdminUser permanently removes customer from state and totalElements', () async {
      bloc.add(const InitializeAdminUsers());
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<AdminUserState>((state) => state.status == AdminUserStatus.loaded)),
      );

      bloc.add(const PermanentlyDeleteAdminUser('6ab6248acf88a4428f9b1e26'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminUserState>((s) =>
              s.actionSuccessMessage == 'User permanently deleted successfully' &&
              s.users.isEmpty &&
              s.totalElements == 0),
        ),
      );
    });
  });

  group('SellerBloc Tests', () {
    late FakeAdminUserRepository repository;
    late SellerBloc bloc;

    setUp(() {
      repository = FakeAdminUserRepository();
      bloc = SellerBloc(repository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('InitializeAdminUsers retrieves sellers and produces sellerProfiles', () async {
      bloc.add(const InitializeAdminUsers());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminUserState>((state) =>
              state.status == AdminUserStatus.loaded &&
              bloc.sellerProfiles.isNotEmpty &&
              bloc.sellerProfiles.first.tradeName == 'Vijay Pal'),
        ),
      );
    });

    test('ToggleDeleteAdminUser updates seller deleted status and reflects in sellerProfiles', () async {
      bloc.add(const InitializeAdminUsers());
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<AdminUserState>((state) => state.status == AdminUserStatus.loaded)),
      );

      bloc.add(const ToggleDeleteAdminUser(
        userId: '6ab62c7f4aec9f42cea26a49',
        deleted: true,
      ));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminUserState>((state) =>
              state.actionSuccessMessage == 'User deactivated successfully' &&
              state.users.first.isDeleted == true &&
              bloc.sellerProfiles.first.isDeleted == true &&
              bloc.sellerProfiles.first.status == 'DEACTIVATED'),
        ),
      );
    });

    test('PermanentlyDeleteAdminUser permanently removes seller from state and sellerProfiles', () async {
      bloc.add(const InitializeAdminUsers());
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<AdminUserState>((state) => state.status == AdminUserStatus.loaded)),
      );

      bloc.add(const PermanentlyDeleteAdminUser('6ab62c7f4aec9f42cea26a49'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminUserState>((state) =>
              state.actionSuccessMessage == 'User permanently deleted successfully' &&
              state.users.isEmpty &&
              bloc.sellerProfiles.isEmpty),
        ),
      );
    });
  });
}
