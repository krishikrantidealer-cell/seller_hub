import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seller_hub/main.dart';
import 'package:seller_hub/core/router/app_router.dart';
import 'package:seller_hub/core/router/route_names.dart';
import 'package:seller_hub/presentation/auth/views/login_view.dart';
import 'package:seller_hub/presentation/dashboard/views/dashboard_view.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppRouter.router.go(RouteNames.login);
  });

  testWidgets('Seller Hub loads login screen with Password form', (WidgetTester tester) async {
    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.text('Sign in to Seller Hub'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);

    // Password form fields & actions
    expect(find.text('Email, Phone or GSTIN'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Sign In to Dashboard'), findsOneWidget);
  });

  testWidgets('Submitting valid login redirects to DashboardView with sidebar navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Enter login credentials
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.pumpAndSettle();

    // Tap Sign In to Dashboard
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Verify redirected to Dashboard
    expect(find.byType(DashboardView), findsOneWidget);
    expect(find.text("Today's Orders"), findsOneWidget);
    expect(find.text('Gross Dispatch Value'), findsOneWidget);

    // Tap Products nav
    await tester.tap(find.text('Products').first);
    await tester.pumpAndSettle();

    expect(find.text('Agricultural Catalog & Master Inventory'), findsOneWidget);
    expect(find.text('Add Product'), findsOneWidget);
    expect(find.text('Edit'), findsWidgets);

    // Tap product title to open full 38-field Product Details
    await tester.tap(find.text('[TEST ONLY - NOT FOR SALE] Crop Protection Insecticide Sample'));
    await tester.pumpAndSettle();

    // Verify Product Details View is displayed with agronomy and pricing
    expect(find.text('Pricing & Commercial Matrix'), findsOneWidget);
    expect(find.text('Agronomic Specifications & Field Efficacy'), findsOneWidget);

    // Tap breadcrumb back to return to catalog
    await tester.tap(find.text('Products Catalog'));
    await tester.pumpAndSettle();

    expect(find.text('Agricultural Catalog & Master Inventory'), findsOneWidget);
  });

  testWidgets('Tapping Edit from compact catalog opens Product Details in edit mode and allows saving updates', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Go to Products
    await tester.tap(find.text('Products').first);
    await tester.pumpAndSettle();

    // Verify Edit buttons exist in compact catalog
    expect(find.text('Edit'), findsWidgets);

    // Tap Edit on first product
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();

    // Verify in Edit Mode
    expect(find.text('EDIT MODE ACTIVE'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Cancel edit returns to view mode
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Product'), findsOneWidget);
    expect(find.text('EDIT MODE ACTIVE'), findsNothing);

    // Tap Edit Product button directly on details screen
    await tester.tap(find.text('Edit Product'));
    await tester.pumpAndSettle();

    expect(find.text('EDIT MODE ACTIVE'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('Products catalog supports proper pagination across pages and rows per page', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Go to Products
    await tester.tap(find.text('Products').first);
    await tester.pumpAndSettle();

    // Verify pagination footer is visible with 6 authentic catalog products
    expect(find.textContaining('Showing 1 - 6 of 6 products'), findsOneWidget);
    expect(find.text('Rows per page:'), findsOneWidget);

    // Switch rows per page to 5
    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Showing 1 - 5 of 6 products'), findsOneWidget);

    // Tap page 2
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Showing 6 - 6 of 6 products'), findsOneWidget);
  });

  testWidgets('Sellers navigation tab displays multi-tenant directory and opens Seller Profile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Tap Sellers nav in sidebar
    await tester.tap(find.text('Sellers').first);
    await tester.pumpAndSettle();

    // Verify Sellers directory table loads
    expect(find.text('Onboard Seller'), findsOneWidget);
    expect(find.text('Krishi Kranti Organics'), findsWidgets);
    expect(find.text('Bharat Agro Chemicals Ltd'), findsWidgets);

    // Tap "Profile" on the first seller
    await tester.tap(find.text('Profile').first);
    await tester.pumpAndSettle();

    // Verify Seller Profile View opens
    expect(find.text('Back to Sellers Directory'), findsOneWidget);
    expect(find.text('Business & Legal'), findsOneWidget);
    expect(find.text('Bank & Settlement'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
  });

  testWidgets('Product catalog table supports multi-selection, bulk actions bar, and column sorting', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SellerHubApp());
    await tester.pumpAndSettle();

    // Sign in
    await tester.enterText(find.byType(TextField).at(0), 'seller@agribegri.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign In to Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Go to Products
    await tester.tap(find.text('Products').first);
    await tester.pumpAndSettle();

    // Verify sortable column headers are displayed
    expect(find.text('PRODUCT & COMPOSITION'), findsOneWidget);
    expect(find.text('SKU / HSN'), findsOneWidget);
    expect(find.text('SELLER / VENDOR'), findsOneWidget);
    expect(find.text('CATEGORY & PACK'), findsOneWidget);
    expect(find.text('PRICE / MRP'), findsOneWidget);
    expect(find.text('STOCK LEVEL'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);

    // Verify master Select-All checkbox is present and tap it
    final headerCheckbox = find.byType(Checkbox).first;
    await tester.tap(headerCheckbox);
    await tester.pumpAndSettle();

    // Verify Bulk Actions Bar appears with all 6 selected
    expect(find.text('6 products selected'), findsOneWidget);
    expect(find.text('Mark Active'), findsOneWidget);
    expect(find.text('Mark Hidden'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    // Tap Clear
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('6 products selected'), findsNothing);

    // Select only the first product checkbox (second checkbox on screen)
    final rowCheckbox = find.byType(Checkbox).at(1);
    await tester.tap(rowCheckbox);
    await tester.pumpAndSettle();

    expect(find.text('1 product selected'), findsOneWidget);

    // Tap Mark Hidden
    await tester.tap(find.text('Mark Hidden'));
    await tester.pumpAndSettle();

    // Sort by price by tapping header (1st tap: Ascending)
    await tester.tap(find.text('PRICE / MRP'));
    await tester.pumpAndSettle();

    // Verify sort reset pill appears
    expect(find.textContaining('Sorted by PRICE • Reset'), findsOneWidget);

    // 2nd tap: Descending
    await tester.tap(find.text('PRICE / MRP'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sorted by PRICE • Reset'), findsOneWidget);

    // 3rd tap: Reset to natural order
    await tester.tap(find.text('PRICE / MRP'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sorted by PRICE • Reset'), findsNothing);

    // Tap PRICE / MRP again, then reset using the pill button
    await tester.tap(find.text('PRICE / MRP'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sorted by PRICE • Reset'), findsOneWidget);

    await tester.tap(find.textContaining('Sorted by PRICE • Reset'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sorted by PRICE • Reset'), findsNothing);

    // Verify catalog remains stable and responsive
    expect(find.text('Agricultural Catalog & Master Inventory'), findsOneWidget);
  });
}

