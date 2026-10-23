import '../../core/models/order.dart';

abstract class SellerOrderRepository {
  Future<List<MarketplaceOrder>> getSellerOrders({int page = 0, int size = 20});
  Future<MarketplaceOrder?> getSellerOrderById(String orderId);
}
