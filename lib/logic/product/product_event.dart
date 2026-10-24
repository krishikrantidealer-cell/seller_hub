import 'package:equatable/equatable.dart';
import '../../core/models/product.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

/// Instant Startup Initializer: Immediately hydrates state with locally cached products (0ms),
/// then runs a silent background network check to verify freshness without showing any loading screen.
class InitializeProducts extends ProductEvent {
  final int page;
  final int size;

  const InitializeProducts({
    this.page = 0,
    this.size = 20,
  });

  @override
  List<Object?> get props => [page, size];
}

class FetchProducts extends ProductEvent {
  final int page;
  final int size;
  final bool isRefresh;
  final bool isBackground;

  const FetchProducts({
    this.page = 0,
    this.size = 20,
    this.isRefresh = false,
    this.isBackground = false,
  });

  @override
  List<Object?> get props => [page, size, isRefresh, isBackground];
}

class SelectProductPage extends ProductEvent {
  final int page;

  const SelectProductPage(this.page);

  @override
  List<Object?> get props => [page];
}

class ChangeProductPageSize extends ProductEvent {
  final int size;

  const ChangeProductPageSize(this.size);

  @override
  List<Object?> get props => [size];
}

class UpdateLocalProduct extends ProductEvent {
  final Product product;
  final bool broadcastWs;

  const UpdateLocalProduct(
    this.product, {
    this.broadcastWs = true,
  });

  @override
  List<Object?> get props => [product, broadcastWs];
}

class WebSocketProductUpdateReceived extends ProductEvent {
  final Map<String, dynamic> payload;

  const WebSocketProductUpdateReceived(this.payload);

  @override
  List<Object?> get props => [payload];
}

class AssignProductCollections extends ProductEvent {
  final String productId;
  final List<String> collectionIds;
  final List<String> subCollectionIds;

  const AssignProductCollections({
    required this.productId,
    required this.collectionIds,
    required this.subCollectionIds,
  });

  @override
  List<Object?> get props => [productId, collectionIds, subCollectionIds];
}
