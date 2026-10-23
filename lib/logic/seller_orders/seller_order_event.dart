import 'package:equatable/equatable.dart';
import '../../core/models/order.dart';

abstract class SellerOrderEvent extends Equatable {
  const SellerOrderEvent();

  @override
  List<Object?> get props => [];
}

class FetchSellerOrdersEvent extends SellerOrderEvent {
  final int page;
  final int size;
  final bool refresh;

  const FetchSellerOrdersEvent({
    this.page = 0,
    this.size = 20,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [page, size, refresh];
}

class SelectSellerOrderEvent extends SellerOrderEvent {
  final String orderId;

  const SelectSellerOrderEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class UpdateLocalSellerOrderEvent extends SellerOrderEvent {
  final MarketplaceOrder order;

  const UpdateLocalSellerOrderEvent(this.order);

  @override
  List<Object?> get props => [order];
}
