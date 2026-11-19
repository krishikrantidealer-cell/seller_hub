import 'package:equatable/equatable.dart';
import 'package:seller_hub/core/models/order.dart';

enum AdminOrderStatus { initial, loading, loaded, error }

class OrderState extends Equatable {
  final AdminOrderStatus status;
  final List<MarketplaceOrder> orders;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  const OrderState({
    this.status = AdminOrderStatus.initial,
    this.orders = const [],
    this.currentPage = 0,
    this.totalPages = 1,
    this.totalElements = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  OrderState copyWith({
    AdminOrderStatus? status,
    List<MarketplaceOrder>? orders,
    int? currentPage,
    int? totalPages,
    int? totalElements,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrderState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        orders,
        currentPage,
        totalPages,
        totalElements,
        hasMore,
        isLoadingMore,
        errorMessage,
      ];
}
