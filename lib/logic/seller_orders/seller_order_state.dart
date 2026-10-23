import 'package:equatable/equatable.dart';
import '../../core/models/order.dart';

abstract class SellerOrderState extends Equatable {
  final List<MarketplaceOrder> orders;

  const SellerOrderState({this.orders = const []});

  @override
  List<Object?> get props => [orders];
}

class SellerOrderInitial extends SellerOrderState {
  const SellerOrderInitial() : super(orders: const []);
}

class SellerOrderLoading extends SellerOrderState {
  const SellerOrderLoading({super.orders});
}

class SellerOrdersLoaded extends SellerOrderState {
  final MarketplaceOrder? selectedOrder;
  final int currentPage;
  final bool hasMore;

  const SellerOrdersLoaded({
    required super.orders,
    this.selectedOrder,
    this.currentPage = 0,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [orders, selectedOrder, currentPage, hasMore];

  SellerOrdersLoaded copyWith({
    List<MarketplaceOrder>? orders,
    MarketplaceOrder? selectedOrder,
    int? currentPage,
    bool? hasMore,
  }) {
    return SellerOrdersLoaded(
      orders: orders ?? this.orders,
      selectedOrder: selectedOrder ?? this.selectedOrder,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class SellerOrderError extends SellerOrderState {
  final String message;

  const SellerOrderError({
    required this.message,
    super.orders,
  });

  @override
  List<Object?> get props => [message, orders];
}
