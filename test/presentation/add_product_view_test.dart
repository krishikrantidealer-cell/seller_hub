import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_hub/core/models/admin_user.dart';
import 'package:seller_hub/core/models/category.dart';
import 'package:seller_hub/core/models/collection.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/logic/admin_user/admin_user_state.dart';
import 'package:seller_hub/logic/admin_user/seller_bloc.dart';
import 'package:seller_hub/logic/category/category_bloc.dart';
import 'package:seller_hub/logic/category/category_state.dart';
import 'package:seller_hub/logic/collection/collection_bloc.dart';
import 'package:seller_hub/logic/collection/collection_state.dart';
import 'package:seller_hub/presentation/dashboard/views/add_product_view.dart';

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
  late MockSellerBloc mockSellerBloc;
  late MockCategoryBloc mockCategoryBloc;
  late MockCollectionBloc mockCollectionBloc;

  final testSellers = [
    const AdminUser(
      id: 'seller_101',
      phoneNumber: '9876543210',
      shopName: 'Green Bio Crops',
      role: 'ROLE_SELLER',
    ),
    const AdminUser(
      id: 'seller_102',
      phoneNumber: '9123456780',
      shopName: 'Krishi Agro Mart',
      role: 'ROLE_SELLER',
    ),
  ];

  final testCategories = [
    const CategoryItem(
      id: 'cat_001',
      name: 'Bio Organic Nutrients',
      slug: 'bio-organic-nutrients',
      level: 0,
    ),
    const CategoryItem(
      id: 'cat_002',
      name: 'Pesticides & Bio-Pesticides',
      slug: 'pesticides',
      level: 0,
    ),
  ];

  final testCollections = [
    const CollectionItem(
      id: 'col_001',
      name: 'Crop Protection',
      slug: 'crop-protection',
      subCollections: [
        SubCollectionItem(id: 'sub_001', name: 'Stem Borer Control', slug: 'stem-borer'),
        SubCollectionItem(id: 'sub_002', name: 'Pest Management', slug: 'pest-management'),
      ],
    ),
    const CollectionItem(
      id: 'col_002',
      name: 'Plant Nutrition',
      slug: 'plant-nutrition',
      subCollections: [
        SubCollectionItem(id: 'sub_003', name: 'Foliar Spray', slug: 'foliar-spray'),
      ],
    ),
  ];

  setUp(() {
    mockSellerBloc = MockSellerBloc(
      AdminUserState(
        status: AdminUserStatus.loaded,
        users: testSellers,
      ),
    );

    mockCategoryBloc = MockCategoryBloc(
      CategoryState(
        status: CategoryStatus.loaded,
        allCategories: testCategories,
        rootCategories: testCategories,
      ),
    );

    mockCollectionBloc = MockCollectionBloc(
      CollectionState(
        status: CollectionStatus.loaded,
        data: CollectionsData(items: testCollections, count: testCollections.length),
      ),
    );
  });

  Widget buildTestableWidget({
    VoidCallback? onBack,
    Function(Product)? onProductAdded,
    String? initialSellerId,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SellerBloc>.value(value: mockSellerBloc),
        BlocProvider<CategoryBloc>.value(value: mockCategoryBloc),
        BlocProvider<CollectionBloc>.value(value: mockCollectionBloc),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AddProductView(
              onBack: onBack ?? () {},
              onProductAdded: onProductAdded ?? (_) {},
              initialSellerId: initialSellerId,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Renders AddProductView as proper full screen with Back to Products button', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Back to Products'), findsOneWidget);
    expect(find.text('Add Agricultural Product'), findsOneWidget);
    expect(find.text('Full Screen Editor'), findsOneWidget);
  });

  testWidgets('No seller is selected at first when opening from product screen', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify placeholder text is shown and helper warning indicates no seller selected
    expect(find.text('-- Select Seller (Required) --'), findsOneWidget);
    expect(find.text('No seller selected initially. Please pick a seller to associate with this product.'), findsOneWidget);
  });

  testWidgets('Vendor field is completely removed from the form', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify vendor field does not exist
    expect(find.text('Vendor / Manufacturer'), findsNothing);
    expect(find.text('Vendor'), findsNothing);
  });

  testWidgets('Collection and Sub-Collection are rendered as interactive dropdowns', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Collection (Dropdown) *'), findsOneWidget);
    expect(find.text('Sub Collection (Dropdown) *'), findsOneWidget);
    expect(find.text('-- Select Collection (Optional) --'), findsOneWidget);
    expect(find.text('-- Select Sub Collection (Optional) --'), findsOneWidget);
  });

  testWidgets('Multi-variants manager allows adding another variant seamlessly', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Switch to tab 2: Multi-Variants
    await tester.tap(find.textContaining('2. Multi-Variants & Pricing'));
    await tester.pumpAndSettle();

    // Initially 1 variant
    expect(find.text('+ Add Another Variant'), findsOneWidget);
    expect(find.text('1 Variant'), findsOneWidget);

    // Tap + Add Another Variant
    await tester.tap(find.text('+ Add Another Variant'));
    await tester.pumpAndSettle();

    // Now 2 variants exist
    expect(find.text('2 Variants'), findsOneWidget);
    expect(find.text('Pack 2'), findsWidgets);
  });

  testWidgets('Category dropdown is rendered prominently at the top alongside Seller', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Category *'), findsOneWidget);
    expect(find.text('Seller (Store Owner) *'), findsOneWidget);
    expect(find.text('-- Select Category (Required) --'), findsOneWidget);
  });

  testWidgets('Category field opens searchable modal picker with real-time search', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Tap on Category selector placeholder
    await tester.tap(find.text('-- Select Category (Required) --'));
    await tester.pumpAndSettle();

    // Dialog should be visible
    expect(find.text('Select Category'), findsOneWidget);
    final searchInput = find.descendant(of: find.byType(Dialog), matching: find.byType(TextField));
    expect(searchInput, findsOneWidget);

    // Enter search text into Category search field
    await tester.enterText(searchInput, 'Pesticides');
    await tester.pumpAndSettle();

    // Option should be filtered in dialog
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('Pesticides & Bio-Pesticides')), findsOneWidget);
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('Bio Organic Nutrients')), findsNothing);

    // Select the filtered category
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Pesticides & Bio-Pesticides')));
    await tester.pumpAndSettle();

    // Dialog closes and new category is displayed
    expect(find.text('Select Category'), findsNothing);
    expect(find.text('Pesticides & Bio-Pesticides'), findsOneWidget);
  });

  testWidgets('Collection field opens searchable modal picker with real-time search', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Tap on Collection selector placeholder
    await tester.tap(find.text('-- Select Collection (Optional) --'));
    await tester.pumpAndSettle();

    // Dialog should be visible
    expect(find.text('Select Collection'), findsOneWidget);
    final searchInput = find.descendant(of: find.byType(Dialog), matching: find.byType(TextField));
    expect(searchInput, findsOneWidget);

    // Enter search text into Collection search field
    await tester.enterText(searchInput, 'Nutrition');
    await tester.pumpAndSettle();

    // Option should be filtered in dialog
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('Plant Nutrition')), findsOneWidget);
    expect(find.descendant(of: find.byType(Dialog), matching: find.text('Crop Protection')), findsNothing);

    // Select filtered collection
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Plant Nutrition')));
    await tester.pumpAndSettle();

    // Dialog closes and new collection is displayed
    expect(find.text('Select Collection'), findsNothing);
    expect(find.text('Plant Nutrition'), findsOneWidget);
  });

  testWidgets('Seller field opens searchable modal picker with seller details', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Tap on Seller selector placeholder
    await tester.tap(find.text('-- Select Seller (Required) --'));
    await tester.pumpAndSettle();

    // Dialog should be visible
    expect(find.text('Select Seller'), findsOneWidget);
    final searchInput = find.descendant(of: find.byType(Dialog), matching: find.byType(TextField));
    expect(searchInput, findsOneWidget);

    // Search for a specific seller
    await tester.enterText(searchInput, 'Green Bio');
    await tester.pumpAndSettle();

    expect(find.text('Green Bio Crops'), findsOneWidget);
    expect(find.text('Krishi Agro Mart'), findsNothing);

    // Select seller
    await tester.tap(find.text('Green Bio Crops'));
    await tester.pumpAndSettle();

    // Dialog closes and seller is selected
    expect(find.text('Select Seller'), findsNothing);
    expect(find.textContaining('Green Bio Crops'), findsOneWidget);
  });
}
