import '../../core/models/order.dart';
import '../../domain/repositories/seller_order_repository.dart';
import '../datasources/seller_order_remote_datasource.dart';

class SellerOrderRepositoryImpl implements SellerOrderRepository {
  final SellerOrderRemoteDataSource _remoteDataSource;

  SellerOrderRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<MarketplaceOrder>> getSellerOrders({int page = 0, int size = 20}) async {
    try {
      final list = await _remoteDataSource.getSellerOrders(page: page, size: size);
      if (list.isNotEmpty) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((json) => MarketplaceOrder.fromJson(json))
            .toList();
      }
    } catch (_) {}

    return List.from(MockOrders.sampleOrders);
  }

  @override
  Future<MarketplaceOrder?> getSellerOrderById(String orderId) async {
    try {
      final data = await _remoteDataSource.getSellerOrderById(orderId);
      if (data.isNotEmpty) {
        return MarketplaceOrder.fromJson(data);
      }
    } catch (_) {}

    final sample = MockOrders.sampleOrders.firstWhere(
      (o) => o.id == orderId || o.orderNumber == orderId,
      orElse: () => MockOrders.sampleOrders.first,
    );
    return sample;
  }
}
