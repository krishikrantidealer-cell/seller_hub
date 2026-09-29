import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/features/auth/seller_login_page.dart';
import 'package:seller_hub/main.dart';

void main() {
  testWidgets('Seller Hub loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    expect(find.byType(SellerLoginPage), findsOneWidget);
    expect(find.text('Welcome back, Partner'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Password'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Mobile OTP'), findsOneWidget);
  });
}
