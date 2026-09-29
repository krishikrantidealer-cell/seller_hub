import 'package:flutter/material.dart';
import 'features/auth/seller_login_page.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SellerHubApp());
}

class SellerHubApp extends StatelessWidget {
  const SellerHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seller Hub — Agri-Commerce Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SellerLoginPage(),
    );
  }
}
