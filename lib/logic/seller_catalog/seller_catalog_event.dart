import 'package:equatable/equatable.dart';
import '../../core/models/product.dart';

abstract class SellerCatalogEvent extends Equatable {
  const SellerCatalogEvent();

  @override
  List<Object?> get props => [];
}

class FetchSellerProductsEvent extends SellerCatalogEvent {
  final int page;
  final int size;
  final bool refresh;

  const FetchSellerProductsEvent({
    this.page = 0,
    this.size = 20,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [page, size, refresh];
}

class SubmitProductListingEvent extends SellerCatalogEvent {
  final Product product;

  const SubmitProductListingEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class UpdateProductListingEvent extends SellerCatalogEvent {
  final Product product;

  const UpdateProductListingEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class FilterSellerCatalogEvent extends SellerCatalogEvent {
  final String? category;
  final String? searchQuery;

  const FilterSellerCatalogEvent({this.category, this.searchQuery});

  @override
  List<Object?> get props => [category, searchQuery];
}
