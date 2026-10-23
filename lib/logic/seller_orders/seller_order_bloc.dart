import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/order.dart';
import '../../domain/repositories/seller_order_repository.dart';
import 'seller_order_event.dart';
import 'seller_order_state.dart';

class SellerOrderBloc extends Bloc<SellerOrderEvent, SellerOrderState> {
  final SellerOrderRepository repository;

  SellerOrderBloc({required this.repository}) : super(const SellerOrderInitial()) {
    on<FetchSellerOrdersEvent>(_onFetchSellerOrders);
    on<SelectSellerOrderEvent>(_onSelectSellerOrder);
    on<UpdateLocalSellerOrderEvent>(_onUpdateLocalSellerOrder);
  }

  Future<void> _onFetchSellerOrders(
    FetchSellerOrdersEvent event,
    Emitter<SellerOrderState> emit,
  ) async {
    emit(SellerOrderLoading(orders: state.orders));
    try {
      final fetched = await repository.getSellerOrders(
        page: event.page,
        size: event.size,
      );

      final List<MarketplaceOrder> merged;
      if (event.refresh || event.page == 0) {
        merged = fetched;
      } else {
        merged = [...state.orders, ...fetched];
      }

      emit(SellerOrdersLoaded(
        orders: merged,
        currentPage: event.page,
        hasMore: fetched.length >= event.size,
      ));
    } catch (e) {
      emit(SellerOrderError(
        message: e.toString(),
        orders: state.orders.isNotEmpty ? state.orders : List.from(MockOrders.sampleOrders),
      ));
    }
  }

  Future<void> _onSelectSellerOrder(
    SelectSellerOrderEvent event,
    Emitter<SellerOrderState> emit,
  ) async {
    try {
      final order = await repository.getSellerOrderById(event.orderId);
      if (order != null) {
        emit(SellerOrdersLoaded(
          orders: state.orders,
          selectedOrder: order,
        ));
      }
    } catch (_) {
      // Keep existing selection if network fails
    }
  }

  void _onUpdateLocalSellerOrder(
    UpdateLocalSellerOrderEvent event,
    Emitter<SellerOrderState> emit,
  ) {
    final updatedList = state.orders.map((o) {
      return (o.id == event.order.id || o.orderNumber == event.order.orderNumber) ? event.order : o;
    }).toList();

    emit(SellerOrdersLoaded(
      orders: updatedList,
      selectedOrder: event.order,
    ));
  }
}
