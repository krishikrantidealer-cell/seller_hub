import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/admin_user.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/websocket_service.dart';
import '../../domain/repositories/admin_user_repository.dart';
import 'admin_user_event.dart';
import 'admin_user_state.dart';

class AdminUserBloc extends Bloc<AdminUserEvent, AdminUserState> {
  final AdminUserRepository repository;
  final String role; // 'SELLERS' or 'CUSTOMERS'
  final WebSocketService _webSocketService;
  StreamSubscription? _wsSubscription;

  AdminUserBloc({
    required this.repository,
    required this.role,
    WebSocketService? webSocketService,
  })  : _webSocketService = webSocketService ?? WebSocketService(),
        super(const AdminUserState()) {
    on<InitializeAdminUsers>(_onInitialize);
    on<FetchAdminUsers>(_onFetchUsers);
    on<LoadMoreAdminUsers>(_onLoadMore);
    on<SearchAdminUsers>(_onSearch);
    on<FilterAdminUsersStatus>(_onFilterStatus);
    on<ToggleBlockAdminUser>(_onToggleBlock);
    on<ToggleDeleteAdminUser>(_onToggleDelete);
    on<PermanentlyDeleteAdminUser>(_onPermanentlyDelete);
    on<CreateAdminUser>(_onCreateUser);
    on<UpdateLocalAdminUser>(_onUpdateLocalUser);
    on<UploadAdminUserKycDocuments>(_onUploadKycDocuments);
    on<ReviewAdminUserKyc>(_onReviewKyc);

    // Live bidirectional WebSocket synchronization
    _wsSubscription = _webSocketService.userUpdates.listen((event) {
      final data = event['data'] ?? event;
      if (data is Map<String, dynamic>) {
        final targetUserId = data['userId']?.toString() ?? data['id']?.toString();
        final kycStatus = data['kycStatus']?.toString();
        if (targetUserId != null && targetUserId.isNotEmpty) {
          final idx = state.users.indexWhere((u) => u.id == targetUserId);
          if (idx >= 0) {
            final current = state.users[idx];
            final updated = current.copyWith(
              kycStatus: kycStatus ?? current.kycStatus,
              isKycComplete: kycStatus == 'APPROVED' ? true : current.isKycComplete,
              isBlocked: data['isBlocked'] is bool ? data['isBlocked'] as bool : current.isBlocked,
              isDeleted: data['isDeleted'] is bool ? data['isDeleted'] as bool : current.isDeleted,
            );
            add(UpdateLocalAdminUser(updated));
            return;
          }
        }
      }
      add(FetchAdminUsers(
        page: state.currentPage,
        size: state.pageSize,
        isBackground: true,
      ));
    });
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onInitialize(
    InitializeAdminUsers event,
    Emitter<AdminUserState> emit,
  ) async {
    // 0ms instant cache hydration
    final cached = await repository.getCachedUsers(role);
    if (cached != null && cached.content.isNotEmpty) {
      emit(state.copyWith(
        status: AdminUserStatus.loaded,
        users: cached.content,
        totalElements: cached.totalElements,
        totalPages: cached.totalPages,
        currentPage: cached.page,
        pageSize: cached.size,
        hasMore: !cached.last,
      ));
    } else {
      emit(state.copyWith(status: AdminUserStatus.loading));
    }

    // Always fetch fresh data from remote
    add(FetchAdminUsers(
      page: 0,
      size: 100,
      isBackground: cached != null && cached.content.isNotEmpty,
    ));
  }

  Future<void> _onFetchUsers(
    FetchAdminUsers event,
    Emitter<AdminUserState> emit,
  ) async {
    if (!event.isBackground && state.users.isEmpty) {
      emit(state.copyWith(status: AdminUserStatus.loading, clearError: true));
    }

    try {
      final pageData = await repository.getUsers(
        role: role,
        page: event.page,
        size: event.size,
        q: event.query,
        blocked: event.blocked,
        deleted: event.deleted,
        forceRefresh: true,
      );

      emit(state.copyWith(
        status: AdminUserStatus.loaded,
        users: pageData.content,
        totalElements: pageData.totalElements,
        totalPages: pageData.totalPages,
        currentPage: pageData.page,
        pageSize: pageData.size,
        hasMore: !pageData.last,
        clearError: true,
      ));
    } catch (e) {
      if (state.users.isEmpty) {
        emit(state.copyWith(
          status: AdminUserStatus.error,
          errorMessage: e is ApiException ? e.message : e.toString(),
        ));
      }
    }
  }

  Future<void> _onLoadMore(
    LoadMoreAdminUsers event,
    Emitter<AdminUserState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final nextPage = state.currentPage + 1;
      final pageData = await repository.getUsers(
        role: role,
        page: nextPage,
        size: state.pageSize,
        forceRefresh: true,
      );

      final combined = List<AdminUser>.from(state.users)..addAll(pageData.content);

      emit(state.copyWith(
        users: combined,
        currentPage: pageData.page,
        hasMore: !pageData.last,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  void _onSearch(SearchAdminUsers event, Emitter<AdminUserState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onFilterStatus(FilterAdminUsersStatus event, Emitter<AdminUserState> emit) {
    emit(state.copyWith(statusFilter: event.status));
  }

  Future<void> _onToggleBlock(
    ToggleBlockAdminUser event,
    Emitter<AdminUserState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, clearError: true, clearActionMessage: true));

    try {
      final updated = await repository.updateUserBlockedStatus(
        userId: event.userId,
        blocked: event.blocked,
      );

      final updatedList = state.users.map((u) {
        return u.id == event.userId ? updated : u;
      }).toList();

      emit(state.copyWith(
        isActionInProgress: false,
        users: updatedList,
        actionSuccessMessage: 'User ${event.blocked ? "blocked" : "unblocked"} successfully',
      ));
      _webSocketService.broadcastUserUpdate({
        'userId': updated.id,
        'isBlocked': updated.isBlocked,
      });
    } catch (e) {
      emit(state.copyWith(
        isActionInProgress: false,
        errorMessage: e is ApiException ? e.message : 'Failed to update user blocked status',
      ));
    }
  }

  Future<void> _onToggleDelete(
    ToggleDeleteAdminUser event,
    Emitter<AdminUserState> emit,
  ) async {
    final previousUsers = state.users;
    final optimisticList = state.users.map((u) {
      return u.id == event.userId ? u.copyWith(isDeleted: event.deleted) : u;
    }).toList();

    // 0ms instant optimistic update so item moves between active & trash immediately
    emit(state.copyWith(
      users: optimisticList,
      isActionInProgress: true,
      clearError: true,
      clearActionMessage: true,
    ));

    try {
      final updated = await repository.updateUserDeletedStatus(
        userId: event.userId,
        deleted: event.deleted,
      );

      final updatedList = state.users.map((u) {
        return u.id == event.userId ? updated : u;
      }).toList();

      emit(state.copyWith(
        isActionInProgress: false,
        users: updatedList,
        actionSuccessMessage: 'User ${event.deleted ? "deactivated" : "restored"} successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        users: previousUsers,
        isActionInProgress: false,
        errorMessage: e is ApiException ? e.message : 'Failed to update user deleted status',
      ));
    }
  }

  Future<void> _onPermanentlyDelete(
    PermanentlyDeleteAdminUser event,
    Emitter<AdminUserState> emit,
  ) async {
    final previousUsers = state.users;
    final previousTotal = state.totalElements;
    final optimisticList = state.users.where((u) => u.id != event.userId).toList();

    emit(state.copyWith(
      users: optimisticList,
      totalElements: state.totalElements > 0 ? state.totalElements - 1 : optimisticList.length,
      isActionInProgress: true,
      clearError: true,
      clearActionMessage: true,
    ));

    try {
      await repository.permanentlyDeleteUser(event.userId);

      emit(state.copyWith(
        isActionInProgress: false,
        actionSuccessMessage: 'User permanently deleted successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        users: previousUsers,
        totalElements: previousTotal,
        isActionInProgress: false,
        errorMessage: e is ApiException ? e.message : 'Failed to permanently delete user',
      ));
    }
  }

  Future<void> _onCreateUser(
    CreateAdminUser event,
    Emitter<AdminUserState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, clearError: true, clearActionMessage: true));

    try {
      final isSeller = role == 'SELLERS';
      final created = isSeller
          ? await repository.createSeller(event.userData)
          : await repository.createCustomer(event.userData);

      final updatedList = [created, ...state.users.where((u) => u.id != created.id)];
      final newTotal = state.totalElements + 1;

      emit(state.copyWith(
        isActionInProgress: false,
        users: updatedList,
        totalElements: newTotal,
        actionSuccessMessage: '${isSeller ? "Seller" : "Customer"} "${created.displayName}" created successfully!',
      ));

      event.onSuccess?.call(created);
    } catch (e) {
      final errorMsg = e is ApiException ? e.message : 'Failed to create user: $e';
      emit(state.copyWith(
        isActionInProgress: false,
        errorMessage: errorMsg,
      ));
      rethrow;
    }
  }

  void _onUpdateLocalUser(
    UpdateLocalAdminUser event,
    Emitter<AdminUserState> emit,
  ) {
    final updatedList = state.users.map((u) {
      return u.id == event.user.id ? event.user : u;
    }).toList();

    emit(state.copyWith(users: updatedList));
  }

  Future<void> _onUploadKycDocuments(
    UploadAdminUserKycDocuments event,
    Emitter<AdminUserState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, clearError: true, clearActionMessage: true));
    try {
      final updated = await repository.uploadKycDocuments(
        userId: event.userId,
        licenceFiles: event.licenceFiles,
        gstCertificate: event.gstCertificate,
        panCard: event.panCard,
        aadhaarCard: event.aadhaarCard,
        replaceLicenceFiles: event.replaceLicenceFiles,
      );

      final updatedList = state.users.map((u) {
        return u.id == updated.id ? updated : u;
      }).toList();

      emit(state.copyWith(
        isActionInProgress: false,
        users: updatedList,
        actionSuccessMessage: 'KYC documents uploaded successfully for "${updated.displayName}"',
      ));

      _webSocketService.broadcastUserUpdate({
        'userId': updated.id,
        'kycStatus': updated.kycStatus,
        'gstCertificate': updated.gstCertificate,
        'panCard': updated.panCard,
        'aadhaarCard': updated.aadhaarCard,
      });

      event.onSuccess?.call(updated);
    } catch (e) {
      final errorMsg = e is ApiException ? e.message : 'Failed to upload KYC documents: $e';
      emit(state.copyWith(
        isActionInProgress: false,
        errorMessage: errorMsg,
      ));
      event.onError?.call(errorMsg);
    }
  }

  Future<void> _onReviewKyc(
    ReviewAdminUserKyc event,
    Emitter<AdminUserState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, clearError: true, clearActionMessage: true));
    try {
      final updated = await repository.reviewSellerKyc(
        userId: event.userId,
        approved: event.approved,
      );

      final updatedList = state.users.map((u) {
        return u.id == updated.id ? updated : u;
      }).toList();

      emit(state.copyWith(
        isActionInProgress: false,
        users: updatedList,
        actionSuccessMessage: event.approved
            ? 'Seller KYC approved successfully for "${updated.displayName}"!'
            : 'Seller KYC returned for review',
      ));

      _webSocketService.broadcastUserUpdate({
        'userId': updated.id,
        'kycStatus': updated.kycStatus,
        'isKycComplete': updated.isKycComplete,
      });

      event.onSuccess?.call(updated);
    } catch (e) {
      final errorMsg = e is ApiException ? e.message : 'Failed to update KYC status: $e';
      emit(state.copyWith(
        isActionInProgress: false,
        errorMessage: errorMsg,
      ));
      event.onError?.call(errorMsg);
    }
  }
}
