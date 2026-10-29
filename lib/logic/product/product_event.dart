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

class FetchAllCatalogProducts extends ProductEvent {
  const FetchAllCatalogProducts();

  @override
  List<Object?> get props => [];
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

class CreateProduct extends ProductEvent {
  final Product product;
  final void Function(Product createdProduct)? onSuccess;
  final void Function(String errorMessage)? onError;

  const CreateProduct(
    this.product, {
    this.onSuccess,
    this.onError,
  });

  @override
  List<Object?> get props => [product];
}

class DeleteProductPermanently extends ProductEvent {
  final String productId;
  final void Function()? onSuccess;
  final void Function(String errorMessage)? onError;

  const DeleteProductPermanently(
    this.productId, {
    this.onSuccess,
    this.onError,
  });

  @override
  List<Object?> get props => [productId];
}

class ToggleProductAvailability extends ProductEvent {
  final String productId;
  final bool isAvailable;
  final void Function(Product updatedProduct)? onSuccess;
  final void Function(String errorMessage)? onError;

  const ToggleProductAvailability({
    required this.productId,
    required this.isAvailable,
    this.onSuccess,
    this.onError,
  });

  @override
  List<Object?> get props => [productId, isAvailable];
}

class UploadProductImages extends ProductEvent {
  final String productId;
  final List<List<int>> filesBytes;
  final List<String> fileNames;
  final void Function(Product updatedProduct)? onSuccess;
  final void Function(String errorMessage)? onError;

  const UploadProductImages({
    required this.productId,
    required this.filesBytes,
    required this.fileNames,
    this.onSuccess,
    this.onError,
  });

  @override
  List<Object?> get props => [productId, fileNames];
}
