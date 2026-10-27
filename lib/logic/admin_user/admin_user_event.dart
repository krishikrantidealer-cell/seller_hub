import 'package:equatable/equatable.dart';

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
