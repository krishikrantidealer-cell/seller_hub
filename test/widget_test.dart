import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/main.dart';
import 'package:seller_hub/presentation/auth/views/login_view.dart';
import 'package:seller_hub/presentation/auth/widgets/otp_login_form.dart';

void main() {
  testWidgets('Seller Hub loads login screen and switches between Password and OTP tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.text('Sign in to Seller Hub'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);
    expect(find.text('Mobile OTP'), findsOneWidget);

    // Initial state: Password form visible
    expect(find.text('Email, Phone or GSTIN'), findsOneWidget);

    // Switch to Mobile OTP tab
    await tester.tap(find.text('Mobile OTP'));
    await tester.pumpAndSettle();

    // Verify OTP form is displayed
    expect(find.byType(OtpLoginForm), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Get OTP Code'), findsOneWidget);

    // Switch back to Password tab (first instance of Password text)
    await tester.tap(find.text('Password').first);
    await tester.pumpAndSettle();

    expect(find.text('Email, Phone or GSTIN'), findsOneWidget);
  });
}
