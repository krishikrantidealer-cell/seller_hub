import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/core/models/order.dart';
import 'package:seller_hub/domain/repositories/seller_order_repository.dart';
import 'package:seller_hub/logic/seller_orders/seller_order_bloc.dart';
import 'package:seller_hub/logic/seller_orders/seller_order_event.dart';
import 'package:seller_hub/logic/seller_orders/seller_order_state.dart';

class FakeSellerOrderRepository implements SellerOrderRepository {
  List<MarketplaceOrder> orders = List.from(MockOrders.sampleOrders);
  bool shouldThrow = false;

  @override
  Future<List<MarketplaceOrder>> getSellerOrders({int page = 0, int size = 20}) async {
    if (shouldThrow) throw Exception('Order fetch failed');
    return orders;
  }

  @override
  Future<MarketplaceOrder?> getSellerOrderById(String orderId) async {
    if (shouldThrow) throw Exception('Order detail failed');
    return orders.firstWhere(
      (o) => o.id == orderId || o.orderNumber == orderId,
      orElse: () => orders.first,
    );
  }
}

void main() {
  group('SellerOrderBloc Tests', () {
    late FakeSellerOrderRepository fakeRepo;
    late SellerOrderBloc bloc;

    setUp(() {
      fakeRepo = FakeSellerOrderRepository();
      bloc = SellerOrderBloc(repository: fakeRepo);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is SellerOrderInitial', () {
      expect(bloc.state, isA<SellerOrderInitial>());
    });

    test('FetchSellerOrdersEvent fetches orders and emits SellerOrdersLoaded', () async {
      final expectedStates = [
        isA<SellerOrderLoading>(),
        isA<SellerOrdersLoaded>().having((s) => s.orders.length, 'orders.length', fakeRepo.orders.length),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const FetchSellerOrdersEvent());
    });

    test('SelectSellerOrderEvent selects order', () async {
      bloc.emit(SellerOrdersLoaded(orders: fakeRepo.orders));

      final targetOrder = fakeRepo.orders.first;
      bloc.add(SelectSellerOrderEvent(targetOrder.id));

      await expectLater(
        bloc.stream,
        emits(isA<SellerOrdersLoaded>().having((s) => s.selectedOrder?.id, 'selectedOrder.id', targetOrder.id)),
      );
    });

    test('UpdateLocalSellerOrderEvent updates order in list', () async {
      bloc.emit(SellerOrdersLoaded(orders: fakeRepo.orders));

      final updated = fakeRepo.orders.first.copyWith(orderStatus: 'DELIVERED');
      bloc.add(UpdateLocalSellerOrderEvent(updated));

      await expectLater(
        bloc.stream,
        emits(isA<SellerOrdersLoaded>().having(
          (s) => s.orders.first.orderStatus,
          'orderStatus',
          'DELIVERED',
        )),
      );
    });

    test('Error during fetch emits SellerOrderError with fallback items', () async {
      fakeRepo.shouldThrow = true;

      final expectedStates = [
        isA<SellerOrderLoading>(),
        isA<SellerOrderError>().having((s) => s.message, 'message', contains('Order fetch failed')),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const FetchSellerOrdersEvent());
    });
  });
}
