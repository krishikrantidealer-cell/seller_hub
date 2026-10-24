import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../network/websocket_service.dart';
import '../storage/token_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/collection_local_datasource.dart';
import '../../data/datasources/collection_remote_datasource.dart';
import '../../data/datasources/product_local_datasource.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/collection_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/repositories/product_repository.dart';

class InjectionContainer {
  static final InjectionContainer instance = InjectionContainer._internal();
  InjectionContainer._internal();

  ApiClient? _apiClient;
  TokenStorage? _tokenStorage;
  AuthRemoteDataSource? _authRemoteDataSource;
  AuthRepository? _authRepository;
  ProductLocalDataSource? _productLocalDataSource;
  ProductRemoteDataSource? _productRemoteDataSource;
  ProductRepository? _productRepository;
  CollectionLocalDataSource? _collectionLocalDataSource;
  CollectionRemoteDataSource? _collectionRemoteDataSource;
  CollectionRepository? _collectionRepository;

  bool _initialized = false;

  Future<void> init({
    http.Client? httpClient,
    SharedPreferences? sharedPreferences,
    String? baseUrl,
    AuthRepository? mockAuthRepository,
    ProductRepository? mockProductRepository,
    CollectionRepository? mockCollectionRepository,
  }) async {
    if (mockAuthRepository != null) {
      _authRepository = mockAuthRepository;
    }
    if (mockProductRepository != null) {
      _productRepository = mockProductRepository;
    }
    if (mockCollectionRepository != null) {
      _collectionRepository = mockCollectionRepository;
    }
    if (mockAuthRepository != null && mockProductRepository != null && mockCollectionRepository != null) {
      _initialized = true;
      return;
    }

    final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
    _tokenStorage = TokenStorage(prefs: prefs);
    WebSocketService().setTokenStorage(_tokenStorage!);

    _apiClient = ApiClient(
      client: httpClient,
      tokenStorage: _tokenStorage,
      baseUrl: baseUrl,
    );
    _authRemoteDataSource ??= AuthRemoteDataSourceImpl(_apiClient!);
    _authRepository ??= AuthRepositoryImpl(
      remoteDataSource: _authRemoteDataSource!,
      tokenStorage: _tokenStorage!,
    );
    _productLocalDataSource ??= ProductLocalDataSourceImpl(prefs);
    _productRemoteDataSource ??= ProductRemoteDataSourceImpl(_apiClient!);
    _productRepository ??= ProductRepositoryImpl(
      remoteDataSource: _productRemoteDataSource!,
      localDataSource: _productLocalDataSource,
    );
    _collectionLocalDataSource ??= CollectionLocalDataSourceImpl(prefs);
    _collectionRemoteDataSource ??= CollectionRemoteDataSourceImpl(_apiClient!);
    _collectionRepository ??= CollectionRepositoryImpl(
      remoteDataSource: _collectionRemoteDataSource!,
      localDataSource: _collectionLocalDataSource,
    );
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  ApiClient get apiClient {
    _ensureInitialized();
    return _apiClient!;
  }

  TokenStorage get tokenStorage {
    _ensureInitialized();
    return _tokenStorage!;
  }

  AuthRemoteDataSource get authRemoteDataSource {
    _ensureInitialized();
    return _authRemoteDataSource!;
  }

  AuthRepository get authRepository {
    _ensureInitialized();
    return _authRepository!;
  }

  ProductRemoteDataSource get productRemoteDataSource {
    _ensureInitialized();
    return _productRemoteDataSource!;
  }

  ProductRepository get productRepository {
    _ensureInitialized();
    return _productRepository!;
  }

  CollectionRemoteDataSource get collectionRemoteDataSource {
    _ensureInitialized();
    return _collectionRemoteDataSource!;
  }

  CollectionRepository get collectionRepository {
    _ensureInitialized();
    return _collectionRepository!;
  }

  ProductLocalDataSource? get productLocalDataSource => _productLocalDataSource;
  CollectionLocalDataSource? get collectionLocalDataSource => _collectionLocalDataSource;

  void _ensureInitialized() {
    if (!_initialized) {
      _tokenStorage = TokenStorage();
      WebSocketService().setTokenStorage(_tokenStorage!);
      _apiClient = ApiClient(tokenStorage: _tokenStorage);
      _authRemoteDataSource = AuthRemoteDataSourceImpl(_apiClient!);
      _authRepository = AuthRepositoryImpl(
        remoteDataSource: _authRemoteDataSource!,
        tokenStorage: _tokenStorage!,
      );
      _productRemoteDataSource = ProductRemoteDataSourceImpl(_apiClient!);
      _productRepository = ProductRepositoryImpl(
        remoteDataSource: _productRemoteDataSource!,
        localDataSource: _productLocalDataSource,
      );
      _collectionRemoteDataSource = CollectionRemoteDataSourceImpl(_apiClient!);
      _collectionRepository = CollectionRepositoryImpl(
        remoteDataSource: _collectionRemoteDataSource!,
        localDataSource: _collectionLocalDataSource,
      );
      _initialized = true;
    }
  }

  void reset() {
    _initialized = false;
    _apiClient = null;
    _tokenStorage = null;
    _authRemoteDataSource = null;
    _authRepository = null;
    _productLocalDataSource = null;
    _productRemoteDataSource = null;
    _productRepository = null;
    _collectionLocalDataSource = null;
    _collectionRemoteDataSource = null;
    _collectionRepository = null;
  }
}
