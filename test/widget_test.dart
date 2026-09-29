import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/main.dart';
import 'package:seller_hub/presentation/auth/views/login_view.dart';

void main() {
  testWidgets('Seller Hub loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.text('Sign in to Seller Hub'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Password'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Mobile OTP'), findsOneWidget);
  });
}
