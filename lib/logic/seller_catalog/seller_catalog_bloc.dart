import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/product.dart';
import '../../domain/repositories/seller_product_repository.dart';
import 'seller_catalog_event.dart';
import 'seller_catalog_state.dart';

class SellerCatalogBloc extends Bloc<SellerCatalogEvent, SellerCatalogState> {
  final SellerProductRepository repository;

  SellerCatalogBloc({required this.repository}) : super(const SellerCatalogInitial()) {
    on<FetchSellerProductsEvent>(_onFetchSellerProducts);
    on<SubmitProductListingEvent>(_onSubmitProductListing);
    on<UpdateProductListingEvent>(_onUpdateProductListing);
  }

  Future<void> _onFetchSellerProducts(
    FetchSellerProductsEvent event,
    Emitter<SellerCatalogState> emit,
  ) async {
    emit(SellerCatalogLoading(products: state.products));
    try {
      final fetched = await repository.getSellerProducts(
        page: event.page,
        size: event.size,
      );

      final List<Product> mergedProducts;
      if (event.refresh || event.page == 0) {
        mergedProducts = fetched;
      } else {
        mergedProducts = [...state.products, ...fetched];
      }

      emit(SellerCatalogLoaded(
        products: mergedProducts,
        currentPage: event.page,
        hasMore: fetched.length >= event.size,
      ));
    } catch (e) {
      emit(SellerCatalogError(
        message: e.toString(),
        products: state.products.isNotEmpty ? state.products : List.from(Product.sampleProducts),
      ));
    }
  }

  Future<void> _onSubmitProductListing(
    SubmitProductListingEvent event,
    Emitter<SellerCatalogState> emit,
  ) async {
    final currentList = state.products;
    emit(SellerCatalogSubmitting(products: currentList));
    try {
      final savedProduct = await repository.submitProductListing(event.product);
      final updatedList = [savedProduct, ...currentList.where((p) => p.productCode != savedProduct.productCode)];

      emit(SellerCatalogActionSuccess(
        products: updatedList,
        message: 'Product "${savedProduct.title}" created successfully.',
        affectedProduct: savedProduct,
      ));
      emit(SellerCatalogLoaded(
        products: updatedList,
        statusMessage: 'Product created successfully',
      ));
    } catch (e) {
      emit(SellerCatalogError(
        message: 'Failed to create product listing: $e',
        products: currentList,
      ));
    }
  }

  Future<void> _onUpdateProductListing(
    UpdateProductListingEvent event,
    Emitter<SellerCatalogState> emit,
  ) async {
    final currentList = state.products;
    emit(SellerCatalogSubmitting(products: currentList));
    try {
      final updatedProduct = await repository.updateProductListing(event.product);
      final exists = currentList.any((p) =>
          p.productCode == updatedProduct.productCode ||
          (p.id.isNotEmpty && p.id == updatedProduct.id));

      final List<Product> updatedList;
      if (exists) {
        updatedList = currentList.map((p) {
          if (p.productCode == updatedProduct.productCode ||
              (p.id.isNotEmpty && p.id == updatedProduct.id)) {
            return updatedProduct;
          }
          return p;
        }).toList();
      } else {
        updatedList = [updatedProduct, ...currentList];
      }

      emit(SellerCatalogActionSuccess(
        products: updatedList,
        message: 'Product "${updatedProduct.title}" updated successfully.',
        affectedProduct: updatedProduct,
      ));
      emit(SellerCatalogLoaded(
        products: updatedList,
        statusMessage: 'Product updated successfully',
      ));
    } catch (e) {
      emit(SellerCatalogError(
        message: 'Failed to update product: $e',
        products: currentList,
      ));
    }
  }
}
