import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/core/models/admin_user.dart';
import 'package:seller_hub/core/models/collection.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/logic/admin_user/admin_user_state.dart';
import 'package:seller_hub/logic/admin_user/seller_bloc.dart';
import 'package:seller_hub/logic/category/category_bloc.dart';
import 'package:seller_hub/logic/category/category_state.dart';
import 'package:seller_hub/logic/collection/collection_bloc.dart';
import 'package:seller_hub/logic/collection/collection_state.dart';
import 'package:seller_hub/logic/product/product_bloc.dart';
import 'package:seller_hub/logic/product/product_event.dart';
import 'package:seller_hub/logic/product/product_state.dart';
import 'package:seller_hub/presentation/dashboard/views/product_details_view.dart';

class MockProductBloc extends Cubit<ProductState> implements ProductBloc {
  MockProductBloc(super.initialState);
  final List<ProductEvent> dispatchedEvents = [];

  @override
  void add(ProductEvent event) {
    dispatchedEvents.add(event);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSellerBloc extends Cubit<AdminUserState> implements SellerBloc {
  MockSellerBloc(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCategoryBloc extends Cubit<CategoryState> implements CategoryBloc {
  MockCategoryBloc(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCollectionBloc extends Cubit<CollectionState> implements CollectionBloc {
  MockCollectionBloc(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockProductBloc mockProductBloc;
  late MockSellerBloc mockSellerBloc;
  late MockCategoryBloc mockCategoryBloc;
  late MockCollectionBloc mockCollectionBloc;

  final testProduct = Product(
    id: 'prod_999',
    productCode: 'PRD-TEST-000999',
    title: 'Bio-Crop Super Booster 500ml',
    sku: 'SKU-BIO-001',
    sellerId: 'seller_mongo_id_123456789',
    sellerName: 'Patel Agro Traders',
    vendor: 'Patel Agro Traders',
    hsnCode: '3101',
    category: 'Fertilizers',
    variants: const [
      ProductVariant(
        id: 'var_1',
        sku: 'SKU-BIO-001-V01',
        label: '500 ml (500ml x 1)',
        displayRate: 250.0,
        printedMrp: 500.0,
        costPrice: 150.0,
        stock: 50,
        packSize: 500,
        unit: 'ml',
        packQuantity: 1,
        isDefault: true,
      ),
      ProductVariant(
        id: 'var_2',
        sku: 'SKU-BIO-001-V02',
        label: '1 ltr (1000ml x 1)',
        displayRate: 450.0,
        printedMrp: 900.0,
        costPrice: 280.0,
        stock: 30,
        packSize: 1000,
        unit: 'ml',
        packQuantity: 1,
        isDefault: false,
      ),
    ],
  );

  setUp(() {
    mockProductBloc = MockProductBloc(ProductState(
      status: ProductStatus.loaded,
      allCatalogProducts: [testProduct],
    ));
    mockSellerBloc = MockSellerBloc(const AdminUserState(
      status: AdminUserStatus.loaded,
      users: [
        AdminUser(
          id: 'seller_mongo_id_123456789',
          shopName: 'Patel Agro Traders',
          phoneNumber: '9876543210',
          role: 'ROLE_SELLER',
        ),
      ],
    ));
    mockCategoryBloc = MockCategoryBloc(const CategoryState(
      status: CategoryStatus.loaded,
      allCategories: [],
    ));
    mockCollectionBloc = MockCollectionBloc(const CollectionState(
      status: CollectionStatus.loaded,
      data: CollectionsData(),
    ));
  });

  Widget createSubject({bool startInEditMode = false}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductBloc>.value(value: mockProductBloc),
        BlocProvider<SellerBloc>.value(value: mockSellerBloc),
        BlocProvider<CategoryBloc>.value(value: mockCategoryBloc),
        BlocProvider<CollectionBloc>.value(value: mockCollectionBloc),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ProductDetailsView(
            product: testProduct,
            onBack: () {},
            startInEditMode: startInEditMode,
          ),
        ),
      ),
    );
  }

  testWidgets('Seller badge displays Seller: Patel Agro Traders and no raw ObjectId', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createSubject(startInEditMode: false));
    await tester.pumpAndSettle();

    // Verify Seller badge displays sellerName
    expect(find.text('Seller: '), findsOneWidget);
    expect(find.text('Patel Agro Traders'), findsWidgets);
    // Verify raw MongoDB ID is not shown as a seller ID badge
    expect(find.textContaining('Seller ID: seller_mongo_id_123456789'), findsNothing);
  });

  testWidgets('1-click Set Default button triggers SetDefaultProductVariant event', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createSubject(startInEditMode: false));
    await tester.pumpAndSettle();

    // Scroll to All Packaging SKUs Matrix
    final setDefaultBtn = find.text('Set Default').first;
    await tester.ensureVisible(setDefaultBtn);
    await tester.pumpAndSettle();

    // Verify Default badge is shown for var_1
    expect(find.text('Default'), findsWidgets);
    expect(setDefaultBtn, findsOneWidget);

    await tester.tap(setDefaultBtn);
    await tester.pump();

    // Verify event dispatched
    expect(
      mockProductBloc.dispatchedEvents.whereType<SetDefaultProductVariant>().isNotEmpty,
      isTrue,
    );
    final event = mockProductBloc.dispatchedEvents.whereType<SetDefaultProductVariant>().first;
    expect(event.productId, equals('prod_999'));
    expect(event.variantId, equals('var_2'));
  });

  testWidgets('Searchable Packaging Dialog opens, filters standards, and updates variant specification', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createSubject(startInEditMode: true));
    await tester.pumpAndSettle();

    // Scroll to Variant Editor card
    final searchStandardsBtn = find.text('Search Standards');
    await tester.ensureVisible(searchStandardsBtn);
    await tester.pumpAndSettle();

    // Verify editor card is rendered
    expect(find.textContaining('Editing SKU #1'), findsOneWidget);
    expect(searchStandardsBtn, findsOneWidget);

    // Tap "Search Standards" to open the searchable packaging dialog
    await tester.tap(searchStandardsBtn);
    await tester.pumpAndSettle();

    // Verify Dialog opened
    expect(find.text('Select Packaging Specification'), findsOneWidget);
    expect(find.text('Search packaging (e.g. 1 ltr, 250ml, 5kg, 10 ltr)...'), findsOneWidget);

    // Filter by category chip
    expect(find.text('Liquid (ml/L)'), findsOneWidget);
    await tester.tap(find.text('Liquid (ml/L)'));
    await tester.pumpAndSettle();

    // Search for 1000ml x 5
    final searchInput = find.widgetWithText(TextField, 'Search packaging (e.g. 1 ltr, 250ml, 5kg, 10 ltr)...');
    await tester.enterText(searchInput, '1000ml x 5');
    await tester.pumpAndSettle();

    // Select "5 ltr (1000ml x 5)" option from filtered results
    final option = find.text('5 ltr (1000ml x 5)').first;
    await tester.tap(option);
    await tester.pumpAndSettle();

    // Verify dialog is closed and variant label updated
    expect(find.text('Select Packaging Specification'), findsNothing);
    expect(find.text('5 ltr (1000ml x 5)'), findsWidgets);
  });
}
