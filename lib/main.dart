import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/theme/theme_bloc.dart';
import 'logic/theme/theme_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SellerHubApp());
}

class SellerHubApp extends StatelessWidget {
  const SellerHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
        BlocProvider<AuthBloc>(create: (_) => AuthBloc()),
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
            themeAnimationDuration: const Duration(milliseconds: 800),
            themeAnimationCurve: Curves.easeInOutCubic,
          );
        },
      ),
    );
  }
}
