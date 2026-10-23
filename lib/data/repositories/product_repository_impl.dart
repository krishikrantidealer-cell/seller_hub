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
}
