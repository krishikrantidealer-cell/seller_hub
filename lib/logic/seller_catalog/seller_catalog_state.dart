import 'package:equatable/equatable.dart';
import '../../core/models/product.dart';

abstract class SellerCatalogState extends Equatable {
  final List<Product> products;

  const SellerCatalogState({this.products = const []});

  @override
  List<Object?> get props => [products];
}

class SellerCatalogInitial extends SellerCatalogState {
  const SellerCatalogInitial() : super(products: const []);
}

class SellerCatalogLoading extends SellerCatalogState {
  const SellerCatalogLoading({super.products});
}

class SellerCatalogLoaded extends SellerCatalogState {
  final int currentPage;
  final bool hasMore;
  final String? statusMessage;

  const SellerCatalogLoaded({
    required super.products,
    this.currentPage = 0,
    this.hasMore = false,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [products, currentPage, hasMore, statusMessage];

  SellerCatalogLoaded copyWith({
    List<Product>? products,
    int? currentPage,
    bool? hasMore,
    String? statusMessage,
  }) {
    return SellerCatalogLoaded(
      products: products ?? this.products,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      statusMessage: statusMessage,
    );
  }
}

class SellerCatalogSubmitting extends SellerCatalogState {
  const SellerCatalogSubmitting({required super.products});
}

class SellerCatalogActionSuccess extends SellerCatalogState {
  final String message;
  final Product affectedProduct;

  const SellerCatalogActionSuccess({
    required super.products,
    required this.message,
    required this.affectedProduct,
  });

  @override
  List<Object?> get props => [products, message, affectedProduct];
}

class SellerCatalogError extends SellerCatalogState {
  final String message;

  const SellerCatalogError({
    required this.message,
    super.products,
  });

  @override
  List<Object?> get props => [message, products];
}
