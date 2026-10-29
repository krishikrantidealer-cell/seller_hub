import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/core/models/category.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/core/models/seller.dart';
import 'package:seller_hub/presentation/dashboard/views/product_catalog_view.dart';

void main() {
  group('ProductCatalogView Level 0 Category Filters', () {
    final List<CategoryItem> sampleLevel0Categories = [
      const CategoryItem(
        id: 'cat_root_1',
        name: 'Crop Protection',
        slug: 'crop-protection',
        parentId: null,
        level: 0,
        iconUrl: '🌾',
      ),
      const CategoryItem(
        id: 'cat_root_2',
        name: 'Seeds',
        slug: 'seeds',
        parentId: null,
        level: 0,
        iconUrl: '🌱',
      ),
      const CategoryItem(
        id: 'cat_root_3',
        name: 'Fertilizers',
        slug: 'fertilizers',
        parentId: null,
        level: 0,
      ),
    ];

    final List<Product> sampleProducts = [
      Product(
        id: 'p1',
        title: 'Beauveria Bassiana Bio Pesticide',
        sku: 'EBS-001',
        productCode: 'PRD-001',
        sellerId: 's1',
        sellerName: 'Patel Agro Traders',
        category: 'Crop Protection',
        categoryId: 'cat_root_1',
      ),
      Product(
        id: 'p2',
        title: 'Hybrid Maize Seeds',
        sku: 'EBS-002',
        productCode: 'PRD-002',
        category: 'Seeds',
        categoryId: 'cat_root_2',
      ),
      Product(
        id: 'p3',
        title: 'Organic Potash Fertilizer',
        sku: 'EBS-003',
        productCode: 'PRD-003',
        category: 'Fertilizers',
        categoryId: 'cat_root_3',
      ),
    ];

    final List<SellerProfile> sampleSellers = [
      const SellerProfile(
        id: 's1',
        companyName: 'Patel Agro Traders',
        tradeName: 'Patel Agro Traders',
        contactPerson: 'Saurabh Patel',
        email: 'patel@example.com',
        phone: '9876501234',
        gstin: '23AAAAA0000A1Z5',
      ),
    ];

    testWidgets('Renders all Level 0 categories as filter chips and filters products', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCatalogView(
              products: sampleProducts,
              sellers: sampleSellers,
              categories: sampleLevel0Categories,
              isWide: true,
              onOpenProductDetails: (_, {bool editMode = false}) {},
              onOpenAddProduct: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 'All' and all Level 0 categories are present in filter chips
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, '🌾 Crop Protection'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, '🌱 Seeds'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Fertilizers'), findsOneWidget);

      // Initially all 3 products are visible
      expect(find.text('Beauveria Bassiana Bio Pesticide'), findsOneWidget);
      expect(find.text('Hybrid Maize Seeds'), findsOneWidget);
      expect(find.text('Organic Potash Fertilizer'), findsOneWidget);

      // Tap on 'Seeds' filter
      await tester.tap(find.widgetWithText(FilterChip, '🌱 Seeds'));
      await tester.pumpAndSettle();

      // Only 'Hybrid Maize Seeds' is visible
      expect(find.text('Hybrid Maize Seeds'), findsOneWidget);
      expect(find.text('Beauveria Bassiana Bio Pesticide'), findsNothing);
      expect(find.text('Organic Potash Fertilizer'), findsNothing);

      // Tap back on 'All'
      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();

      // All products return
      expect(find.text('Beauveria Bassiana Bio Pesticide'), findsOneWidget);
      expect(find.text('Hybrid Maize Seeds'), findsOneWidget);
      expect(find.text('Organic Potash Fertilizer'), findsOneWidget);
    });

    testWidgets('Metric boxes removed, seller phone number displayed in table, and All Sellers dropdown displays seller count', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCatalogView(
              products: sampleProducts,
              sellers: sampleSellers,
              categories: sampleLevel0Categories,
              isWide: true,
              onOpenProductDetails: (_, {bool editMode = false}) {},
              onOpenAddProduct: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify metric boxes for 'Total', 'In Stock', 'Low Stock', 'Sellers' are removed
      expect(find.text('In Stock: '), findsNothing);
      expect(find.text('Low Stock: '), findsNothing);
      expect(find.text('Sellers: '), findsNothing);

      // 2. Verify seller phone number is displayed instead of raw seller id
      expect(find.text('9876501234'), findsOneWidget);
      expect(find.text('ID: s1'), findsNothing);

      // 3. Verify 'All Sellers' dropdown shows seller count (1 seller) not product count (3)
      expect(find.text('All Sellers'), findsWidgets);
      expect(find.text('1'), findsWidgets); // 1 seller in sampleSellers
    });
  });
}
