import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/collection_repository.dart';
import 'domain/repositories/product_repository.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/auth/auth_event.dart';
import 'logic/collection/collection_bloc.dart';
import 'logic/collection/collection_event.dart';
import 'logic/product/product_bloc.dart';
import 'logic/product/product_event.dart';
import 'logic/theme/theme_bloc.dart';
import 'logic/theme/theme_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InjectionContainer.instance.init();
  runApp(const SellerHubApp());
}

class SellerHubApp extends StatelessWidget {
  final AuthRepository? authRepository;
  final ProductRepository? productRepository;
  final CollectionRepository? collectionRepository;

  const SellerHubApp({
    super.key,
    this.authRepository,
    this.productRepository,
    this.collectionRepository,
  });

  @override
  Widget build(BuildContext context) {
    final authRepo = authRepository ?? InjectionContainer.instance.authRepository;
    final productRepo = productRepository ?? InjectionContainer.instance.productRepository;
    final collectionRepo = collectionRepository ?? InjectionContainer.instance.collectionRepository;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepo),
        RepositoryProvider<ProductRepository>.value(value: productRepo),
        RepositoryProvider<CollectionRepository>.value(value: collectionRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
          BlocProvider<AuthBloc>(
            create: (ctx) => AuthBloc(
              authRepository: ctx.read<AuthRepository>(),
            )..add(CheckAuthStatus()),
          ),
          BlocProvider<ProductBloc>(
            create: (ctx) => ProductBloc(
              productRepository: ctx.read<ProductRepository>(),
            )..add(const InitializeProducts(page: 0, size: 20)),
          ),
          BlocProvider<CollectionBloc>(
            create: (ctx) => CollectionBloc(
              collectionRepository: ctx.read<CollectionRepository>(),
            )..add(const InitializeCollections()),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp.router(
              title: '${themeState.brandName} — Enterprise Agri-Commerce',
              debugShowCheckedModeBanner: false,
              routerConfig: AppRouter.router,
              theme: AppTheme.createTheme(
                palette: themeState.currentPalette,
                isDark: false,
              ),
              darkTheme: AppTheme.createTheme(
                palette: themeState.currentPalette,
                isDark: true,
              ),
              themeMode: themeState.isDark ? ThemeMode.dark : ThemeMode.light,
              themeAnimationDuration: const Duration(milliseconds: 480),
              themeAnimationCurve: Curves.easeInOutCubic,
            );
          },
        ),
      ),
    );
  }
}
