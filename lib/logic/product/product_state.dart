import 'package:equatable/equatable.dart';
import '../../core/models/product.dart';

enum ProductStatus { initial, loading, loaded, error }

class ProductState extends Equatable {
  final ProductStatus status;
  final ProductPageData pageData;
  final int currentPage;
  final int pageSize;
  final String? errorMessage;
  final bool isBackgroundSyncing;
  final bool isAssigningCollections;
  final String? assignCollectionsError;
  final Product? lastAssignedProduct;

  const ProductState({
    this.status = ProductStatus.initial,
    this.pageData = const ProductPageData(),
    this.currentPage = 0,
    this.pageSize = 20,
    this.errorMessage,
    this.isBackgroundSyncing = false,
    this.isAssigningCollections = false,
    this.assignCollectionsError,
    this.lastAssignedProduct,
  });

  List<Product> get products => pageData.content;
  int get totalProducts => pageData.totalElements;
  int get totalPages => pageData.totalPages > 0 ? pageData.totalPages : 1;
  bool get hasProducts => pageData.content.isNotEmpty;

  ProductState copyWith({
    ProductStatus? status,
    ProductPageData? pageData,
    int? currentPage,
    int? pageSize,
    String? errorMessage,
    bool? isBackgroundSyncing,
    bool? isAssigningCollections,
    String? assignCollectionsError,
    Product? lastAssignedProduct,
    bool clearLastAssignedProduct = false,
  }) {
    return ProductState(
      status: status ?? this.status,
      pageData: pageData ?? this.pageData,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      errorMessage: errorMessage,
      isBackgroundSyncing: isBackgroundSyncing ?? this.isBackgroundSyncing,
      isAssigningCollections: isAssigningCollections ?? this.isAssigningCollections,
      assignCollectionsError: assignCollectionsError,
      lastAssignedProduct: clearLastAssignedProduct
          ? null
          : (lastAssignedProduct ?? this.lastAssignedProduct),
    );
  }

  @override
  List<Object?> get props => [
    status,
    pageData,
    currentPage,
    pageSize,
    errorMessage,
    isBackgroundSyncing,
    isAssigningCollections,
    assignCollectionsError,
    lastAssignedProduct,
  ];
}
