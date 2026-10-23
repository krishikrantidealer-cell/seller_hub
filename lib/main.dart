import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/auth_repository.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/auth/auth_event.dart';
import 'logic/theme/theme_bloc.dart';
import 'logic/theme/theme_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InjectionContainer.instance.init();
  runApp(const SellerHubApp());
}

class SellerHubApp extends StatelessWidget {
  final AuthRepository? authRepository;

  const SellerHubApp({super.key, this.authRepository});

  @override
  Widget build(BuildContext context) {
    final repo = authRepository ?? InjectionContainer.instance.authRepository;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: repo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
          BlocProvider<AuthBloc>(
            create: (ctx) => AuthBloc(
              authRepository: ctx.read<AuthRepository>(),
            )..add(CheckAuthStatus()),
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
