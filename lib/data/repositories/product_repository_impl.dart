import '../../core/models/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource? localDataSource;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
  });

  @override
  Future<ProductPageData> getProducts({
    int page = 0,
    int size = 20,
  }) async {
    final responseDto = await remoteDataSource.getProducts(
      page: page,
      size: size,
    );
    final data = responseDto.data!;
    // Asynchronously update local cache so next restarts load with 0ms delay
    localDataSource?.cachePage(page, size, data);
    return data;
  }

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      final List<Product> all = [];
      int page = 0;
      const int pageSize = 100;
      int totalPages = 1;

      while (page < totalPages) {
        final pageData = await getProducts(page: page, size: pageSize);
        all.addAll(pageData.content);
        totalPages = pageData.totalPages;
        page++;
        if (pageData.content.isEmpty || page >= 20) break;
      }
      return all;
    } catch (_) {
      final cached = await getCachedProducts(page: 0, size: 100) ??
          await getCachedProducts(page: 0, size: 20);
      return cached?.content ?? [];
    }
  }

  @override
  Future<ProductPageData?> getCachedProducts({
    int page = 0,
    int size = 20,
  }) async {
    return localDataSource?.getCachedPage(page, size);
  }

  @override
  Future<void> updateLocalProduct(Product product) async {
    await localDataSource?.updateCachedProduct(product);
  }

  @override
  Future<Product> assignCollections({
    required String productId,
    required List<String> collectionIds,
    required List<String> subCollectionIds,
  }) async {
    final updatedProduct = await remoteDataSource.assignCollections(
      productId: productId,
      collectionIds: collectionIds,
      subCollectionIds: subCollectionIds,
    );
    await localDataSource?.updateCachedProduct(updatedProduct);
    return updatedProduct;
  }

  @override
  Future<Product> createProduct(Product product) async {
    final created = await remoteDataSource.createProduct(
      product.toAdminCreatePayload(),
    );
    await localDataSource?.updateCachedProduct(created);
    return created;
  }
}
