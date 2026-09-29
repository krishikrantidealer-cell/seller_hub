import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';
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
    expect(find.text('Send OTP Verification Code'), findsOneWidget);

    // Enter 10-digit phone number and request OTP
    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.pumpAndSettle();

    expect(find.text('10 Digits'), findsOneWidget);

    await tester.tap(find.text('Send OTP Verification Code'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify Pinput widget is displayed
    expect(find.byType(Pinput), findsOneWidget);
    expect(find.text('+91 9876543210'), findsOneWidget);

    // Switch back to Password tab (first instance of Password text)
    await tester.tap(find.text('Password').first);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Email, Phone or GSTIN'), findsOneWidget);
  });
}
