import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/admin_user.dart';
import '../../core/network/api_exception.dart';
import '../../domain/repositories/admin_user_repository.dart';
import 'admin_user_event.dart';
import 'admin_user_state.dart';

class AdminUserBloc extends Bloc<AdminUserEvent, AdminUserState> {
  final AdminUserRepository repository;
  final String role; // 'SELLERS' or 'CUSTOMERS'

  AdminUserBloc({
    required this.repository,
    required this.role,
  }) : super(const AdminUserState()) {
    on<InitializeAdminUsers>(_onInitialize);
    on<FetchAdminUsers>(_onFetchUsers);
    on<LoadMoreAdminUsers>(_onLoadMore);
    on<SearchAdminUsers>(_onSearch);
    on<FilterAdminUsersStatus>(_onFilterStatus);
    on<ToggleBlockAdminUser>(_onToggleBlock);
    on<ToggleDeleteAdminUser>(_onToggleDelete);
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
      size: state.pageSize,
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
    emit(state.copyWith(isActionInProgress: true, clearError: true, clearActionMessage: true));

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
        actionSuccessMessage: 'User ${event.deleted ? "deleted" : "restored"} successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        isActionInProgress: false,
        errorMessage: e is ApiException ? e.message : 'Failed to update user deleted status',
      ));
    }
  }
}
