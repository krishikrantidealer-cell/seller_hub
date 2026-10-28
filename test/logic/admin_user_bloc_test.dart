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
              s.actionSuccessMessage == 'User deleted successfully' &&
              s.users.first.isDeleted == true),
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
              state.actionSuccessMessage == 'User deleted successfully' &&
              state.users.first.isDeleted == true &&
              bloc.sellerProfiles.first.isDeleted == true &&
              bloc.sellerProfiles.first.status == 'DEACTIVATED'),
        ),
      );
    });
  });
}
