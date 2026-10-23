import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/category_repository.dart';
import 'domain/repositories/seller_auth_repository.dart';
import 'domain/repositories/seller_order_repository.dart';
import 'domain/repositories/seller_product_repository.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/auth/auth_event.dart';
import 'logic/seller_catalog/seller_catalog_bloc.dart';
import 'logic/seller_catalog/seller_catalog_event.dart';
import 'logic/seller_orders/seller_order_bloc.dart';
import 'logic/seller_orders/seller_order_event.dart';
import 'logic/theme/theme_bloc.dart';
import 'logic/theme/theme_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InjectionContainer.instance.init();
  runApp(const SellerHubApp());
}

class SellerHubApp extends StatelessWidget {
  const SellerHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final di = InjectionContainer.instance;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SellerAuthRepository>.value(value: di.sellerAuthRepository),
        RepositoryProvider<SellerProductRepository>.value(value: di.sellerProductRepository),
        RepositoryProvider<SellerOrderRepository>.value(value: di.sellerOrderRepository),
        RepositoryProvider<CategoryRepository>.value(value: di.categoryRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
          BlocProvider<AuthBloc>(
            create: (ctx) => AuthBloc(
              authRepository: ctx.read<SellerAuthRepository>(),
            )..add(CheckAuthStatus()),
          ),
          BlocProvider<SellerCatalogBloc>(
            create: (ctx) => SellerCatalogBloc(
              repository: ctx.read<SellerProductRepository>(),
            )..add(const FetchSellerProductsEvent()),
          ),
          BlocProvider<SellerOrderBloc>(
            create: (ctx) => SellerOrderBloc(
              repository: ctx.read<SellerOrderRepository>(),
            )..add(const FetchSellerOrdersEvent()),
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
