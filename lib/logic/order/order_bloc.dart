import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seller_hub/core/constants/api_endpoints.dart';
import 'package:seller_hub/core/models/order.dart';
import 'package:seller_hub/core/network/api_client.dart';
import 'package:seller_hub/core/network/api_exception.dart';
import 'package:seller_hub/core/network/websocket_service.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final ApiClient apiClient;
  final WebSocketService webSocketService;
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  Timer? _autoRefreshTimer;
  bool _isFetching = false;
  bool _pendingRefresh = false;

  void _ensureAutoRefreshStarted() {
    _autoRefreshTimer ??= Timer.periodic(const Duration(seconds: 15), (_) {
      if (isClosed) {
        _autoRefreshTimer?.cancel();
        _autoRefreshTimer = null;
        return;
      }
      if (!_isFetching) {
        add(const LoadAdminOrders(page: 0, size: 50, isRefresh: true));
      }
    });
  }

  OrderBloc({
    required this.apiClient,
    WebSocketService? webSocketService,
  })  : webSocketService = webSocketService ?? WebSocketService(),
        super(const OrderState()) {
    on<LoadAdminOrders>(_onLoadAdminOrders);
    on<LoadMoreAdminOrders>(_onLoadMoreAdminOrders);
    on<UpdateAdminOrderLocal>(_onUpdateAdminOrderLocal);
    on<ResetAdminOrders>(_onResetAdminOrders);

    _wsSub = this.webSocketService.orderUpdates.listen((_) {
      if (_isFetching) {
        _pendingRefresh = true;
      } else {
        add(const LoadAdminOrders(page: 0, size: 50, isRefresh: true));
      }
    });
  }

  Future<void> _onLoadAdminOrders(
    LoadAdminOrders event,
    Emitter<OrderState> emit,
  ) async {
    _ensureAutoRefreshStarted();
    if (_isFetching) {
      _pendingRefresh = true;
      return;
    }
    _isFetching = true;
    if (!event.isRefresh && state.orders.isEmpty) {
      emit(state.copyWith(status: AdminOrderStatus.loading, clearError: true));
    }

    try {
      final response = await apiClient.get(
        ApiEndpoints.adminOrders,
        queryParameters: {'page': event.page, 'size': event.size},
        requiresAuth: true,
      );
      final parsed = _parsePagedOrders(response, fallbackPage: event.page);
      emit(state.copyWith(
        status: AdminOrderStatus.loaded,
        orders: parsed.items,
        currentPage: parsed.page,
        totalPages: parsed.totalPages,
        totalElements: parsed.totalElements,
        hasMore: parsed.hasMore,
        isLoadingMore: false,
        clearError: true,
      ));
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to load orders: $e';
      emit(state.copyWith(
        status: state.orders.isEmpty ? AdminOrderStatus.error : AdminOrderStatus.loaded,
        isLoadingMore: false,
        errorMessage: msg,
      ));
    } finally {
      _isFetching = false;
      if (_pendingRefresh) {
        _pendingRefresh = false;
        add(const LoadAdminOrders(page: 0, size: 50, isRefresh: true));
      }
    }
  }

  Future<void> _onLoadMoreAdminOrders(
    LoadMoreAdminOrders event,
    Emitter<OrderState> emit,
  ) async {
    if (_isFetching || !state.hasMore || state.isLoadingMore) return;
    _isFetching = true;
    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final nextPage = state.currentPage + 1;
      final response = await apiClient.get(
        ApiEndpoints.adminOrders,
        queryParameters: {'page': nextPage, 'size': 50},
        requiresAuth: true,
      );
      final parsed = _parsePagedOrders(response, fallbackPage: nextPage);
      final merged = List<MarketplaceOrder>.from(state.orders);
      final existingIds = merged.map((o) => o.id).toSet();
      for (final item in parsed.items) {
        if (!existingIds.contains(item.id)) {
          merged.add(item);
        }
      }
      emit(state.copyWith(
        status: AdminOrderStatus.loaded,
        orders: merged,
        currentPage: parsed.page,
        totalPages: parsed.totalPages,
        totalElements: parsed.totalElements,
        hasMore: parsed.hasMore,
        isLoadingMore: false,
        clearError: true,
      ));
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to load more orders: $e';
      emit(state.copyWith(isLoadingMore: false, errorMessage: msg));
    } finally {
      _isFetching = false;
    }
  }

  void _onUpdateAdminOrderLocal(
    UpdateAdminOrderLocal event,
    Emitter<OrderState> emit,
  ) {
    final updatedList = state.orders
        .map((o) => o.id == event.order.id ? event.order : o)
        .toList();
    if (!updatedList.any((o) => o.id == event.order.id)) {
      updatedList.insert(0, event.order);
    }
    emit(state.copyWith(status: AdminOrderStatus.loaded, orders: updatedList));
  }

  void _onResetAdminOrders(
    ResetAdminOrders event,
    Emitter<OrderState> emit,
  ) {
    emit(const OrderState());
  }

  _ParsedOrdersPage _parsePagedOrders(
    Map<String, dynamic> response, {
    required int fallbackPage,
  }) {
    final data = response['data'];
    List<dynamic> rawList = const [];
    int page = fallbackPage;
    int totalPages = 1;
    int totalElements = 0;
    bool hasMore = false;

    if (data is Map) {
      if (data['content'] is List) {
        rawList = data['content'] as List<dynamic>;
      }
      page = (data['page'] is num) ? (data['page'] as num).toInt() : fallbackPage;
      totalPages = (data['totalPages'] is num) ? (data['totalPages'] as num).toInt() : 1;
      totalElements = (data['totalElements'] is num)
          ? (data['totalElements'] as num).toInt()
          : rawList.length;
      final isLast = data['last'] == true;
      hasMore = !isLast && (page + 1 < totalPages);
    } else if (data is List) {
      rawList = data;
      totalElements = rawList.length;
    }

    final parsed = rawList
        .whereType<Map>()
        .map((raw) => MarketplaceOrder.fromBackendJson(Map<String, dynamic>.from(raw)))
        .toList();

    return _ParsedOrdersPage(
      items: parsed,
      page: page,
      totalPages: totalPages,
      totalElements: totalElements,
      hasMore: hasMore,
    );
  }

  @override
  Future<void> close() {
    _autoRefreshTimer?.cancel();
    _wsSub?.cancel();
    return super.close();
  }
}

class _ParsedOrdersPage {
  final List<MarketplaceOrder> items;
  final int page;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  const _ParsedOrdersPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });
}
