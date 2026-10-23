import '../network/api_client.dart';
import '../storage/token_storage.dart';
import '../../domain/repositories/seller_auth_repository.dart';
import '../../domain/repositories/seller_product_repository.dart';
import '../../domain/repositories/seller_order_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../data/datasources/seller_auth_remote_datasource.dart';
import '../../data/datasources/seller_product_remote_datasource.dart';
import '../../data/datasources/seller_order_remote_datasource.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../data/repositories/seller_auth_repository_impl.dart';
import '../../data/repositories/seller_product_repository_impl.dart';
import '../../data/repositories/seller_order_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';

class InjectionContainer {
  static final InjectionContainer instance = InjectionContainer._internal();
  factory InjectionContainer() => instance;
  InjectionContainer._internal();

  TokenStorage? _tokenStorage;
  ApiClient? _apiClient;
  SellerAuthRepository? _sellerAuthRepository;
  SellerProductRepository? _sellerProductRepository;
  SellerOrderRepository? _sellerOrderRepository;
  CategoryRepository? _categoryRepository;

  bool _isInitialized = false;

  Future<void> init({TokenStorage? customTokenStorage, ApiClient? customApiClient}) async {
    if (_isInitialized) return;

    _tokenStorage = customTokenStorage ?? await TokenStorage.create();
    _apiClient = customApiClient ?? ApiClient(tokenStorage: _tokenStorage!);

    final authRemoteDataSource = SellerAuthRemoteDataSourceImpl(_apiClient!);
    final productRemoteDataSource = SellerProductRemoteDataSourceImpl(_apiClient!);
    final orderRemoteDataSource = SellerOrderRemoteDataSourceImpl(_apiClient!);
    final categoryRemoteDataSource = CategoryRemoteDataSourceImpl(_apiClient!);

    _sellerAuthRepository = SellerAuthRepositoryImpl(
      authRemoteDataSource,
      _tokenStorage!,
    );
    _sellerProductRepository = SellerProductRepositoryImpl(
      productRemoteDataSource,
    );
    _sellerOrderRepository = SellerOrderRepositoryImpl(
      orderRemoteDataSource,
    );
    _categoryRepository = CategoryRepositoryImpl(
      categoryRemoteDataSource,
    );

    _isInitialized = true;
  }

  TokenStorage get tokenStorage {
    _tokenStorage ??= TokenStorage();
    return _tokenStorage!;
  }

  ApiClient get apiClient {
    _apiClient ??= ApiClient(tokenStorage: tokenStorage);
    return _apiClient!;
  }

  SellerAuthRepository get sellerAuthRepository {
    _sellerAuthRepository ??= SellerAuthRepositoryImpl(
      SellerAuthRemoteDataSourceImpl(apiClient),
      tokenStorage,
    );
    return _sellerAuthRepository!;
  }

  SellerProductRepository get sellerProductRepository {
    _sellerProductRepository ??= SellerProductRepositoryImpl(
      SellerProductRemoteDataSourceImpl(apiClient),
    );
    return _sellerProductRepository!;
  }

  SellerOrderRepository get sellerOrderRepository {
    _sellerOrderRepository ??= SellerOrderRepositoryImpl(
      SellerOrderRemoteDataSourceImpl(apiClient),
    );
    return _sellerOrderRepository!;
  }

  CategoryRepository get categoryRepository {
    _categoryRepository ??= CategoryRepositoryImpl(
      CategoryRemoteDataSourceImpl(apiClient),
    );
    return _categoryRepository!;
  }
}
