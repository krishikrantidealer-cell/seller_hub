import 'package:flutter/material.dart';
import 'features/auth/seller_login_page.dart';
import 'theme/app_theme.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SellerHubApp());
}

class SellerHubApp extends StatelessWidget {
  const SellerHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Seller Hub — Agri-Commerce Portal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const SellerLoginPage(),
        );
      },
    );
  }
}
