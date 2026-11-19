import 'package:equatable/equatable.dart';
import 'package:seller_hub/core/models/order.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class LoadAdminOrders extends OrderEvent {
  final int page;
  final int size;
  final bool isRefresh;

  const LoadAdminOrders({
    this.page = 0,
    this.size = 50,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [page, size, isRefresh];
}

class LoadMoreAdminOrders extends OrderEvent {
  const LoadMoreAdminOrders();
}

class UpdateAdminOrderLocal extends OrderEvent {
  final MarketplaceOrder order;

  const UpdateAdminOrderLocal(this.order);

  @override
  List<Object?> get props => [order];
}

class ResetAdminOrders extends OrderEvent {
  const ResetAdminOrders();
}
