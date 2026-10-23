import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

class InjectionContainer {
  static final InjectionContainer instance = InjectionContainer._internal();
  InjectionContainer._internal();

  ApiClient? _apiClient;
  TokenStorage? _tokenStorage;
  AuthRemoteDataSource? _authRemoteDataSource;
  AuthRepository? _authRepository;

  bool _initialized = false;

  Future<void> init({
    http.Client? httpClient,
    SharedPreferences? sharedPreferences,
    String? baseUrl,
    AuthRepository? mockAuthRepository,
  }) async {
    if (mockAuthRepository != null) {
      _authRepository = mockAuthRepository;
      _initialized = true;
      return;
    }

    final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
    _tokenStorage = TokenStorage(prefs: prefs);
    _apiClient = ApiClient(
      client: httpClient,
      tokenStorage: _tokenStorage,
      baseUrl: baseUrl,
    );
    _authRemoteDataSource = AuthRemoteDataSourceImpl(_apiClient!);
    _authRepository = AuthRepositoryImpl(
      remoteDataSource: _authRemoteDataSource!,
      tokenStorage: _tokenStorage!,
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

  void _ensureInitialized() {
    if (!_initialized) {
      _tokenStorage = TokenStorage();
      _apiClient = ApiClient(tokenStorage: _tokenStorage);
      _authRemoteDataSource = AuthRemoteDataSourceImpl(_apiClient!);
      _authRepository = AuthRepositoryImpl(
        remoteDataSource: _authRemoteDataSource!,
        tokenStorage: _tokenStorage!,
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
  }
}
