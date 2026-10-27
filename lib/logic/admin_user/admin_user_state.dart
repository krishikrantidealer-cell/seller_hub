import 'package:equatable/equatable.dart';
import '../../core/models/admin_user.dart';

enum AdminUserStatus { initial, loading, loaded, error }

class AdminUserState extends Equatable {
  final AdminUserStatus status;
  final List<AdminUser> users;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final bool hasMore;
  final bool isLoadingMore;
  final String searchQuery;
  final String statusFilter; // 'ALL', 'VERIFIED', 'KYC_PENDING', 'BLOCKED'
  final bool isActionInProgress;
  final String? errorMessage;
  final String? actionSuccessMessage;

  const AdminUserState({
    this.status = AdminUserStatus.initial,
    this.users = const [],
    this.totalElements = 0,
    this.totalPages = 1,
    this.currentPage = 0,
    this.pageSize = 20,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.statusFilter = 'ALL',
    this.isActionInProgress = false,
    this.errorMessage,
    this.actionSuccessMessage,
  });

  int get totalCount => totalElements > 0 ? totalElements : users.length;
  int get verifiedCount => users.where((u) => u.isVerified).length;
  int get kycPendingCount => users.where((u) => !u.isKycComplete).length;
  int get blockedCount => users.where((u) => u.isBlocked).length;

  /// Returns users matching the active search query and status filter
  List<AdminUser> get filteredUsers {
    final query = searchQuery.trim().toLowerCase();
    return users.where((u) {
      if (query.isNotEmpty) {
        final matchesName = u.fullName.toLowerCase().contains(query);
        final matchesShop = (u.shopName ?? '').toLowerCase().contains(query);
        final matchesPhone = u.phoneNumber.toLowerCase().contains(query);
        final matchesEmail = (u.email ?? '').toLowerCase().contains(query);
        final matchesCity = (u.address?.cityTehsil ?? '').toLowerCase().contains(query);
        final matchesState = (u.address?.state ?? '').toLowerCase().contains(query);
        final matchesId = u.id.toLowerCase().contains(query);

        if (!matchesName && !matchesShop && !matchesPhone && !matchesEmail && !matchesCity && !matchesState && !matchesId) {
          return false;
        }
      }

      if (statusFilter == 'VERIFIED' && !u.isVerified) return false;
      if (statusFilter == 'KYC_PENDING' && u.isKycComplete) return false;
      if (statusFilter == 'BLOCKED' && !u.isBlocked) return false;

      return true;
    }).toList();
  }

  AdminUserState copyWith({
    AdminUserStatus? status,
    List<AdminUser>? users,
    int? totalElements,
    int? totalPages,
    int? currentPage,
    int? pageSize,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchQuery,
    String? statusFilter,
    bool? isActionInProgress,
    String? errorMessage,
    String? actionSuccessMessage,
    bool clearError = false,
    bool clearActionMessage = false,
  }) {
    return AdminUserState(
      status: status ?? this.status,
      users: users ?? this.users,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionSuccessMessage: clearActionMessage ? null : (actionSuccessMessage ?? this.actionSuccessMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        users,
        totalElements,
        totalPages,
        currentPage,
        pageSize,
        hasMore,
        isLoadingMore,
        searchQuery,
        statusFilter,
        isActionInProgress,
        errorMessage,
        actionSuccessMessage,
      ];
}
