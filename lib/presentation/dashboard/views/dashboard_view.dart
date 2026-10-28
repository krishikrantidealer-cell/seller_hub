import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/models/order.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/core/models/seller.dart';
import 'package:seller_hub/core/network/websocket_service.dart';
import 'package:seller_hub/core/router/route_names.dart';
import 'package:seller_hub/logic/auth/auth_bloc.dart';
import 'package:seller_hub/logic/auth/auth_event.dart';
import 'package:seller_hub/logic/category/category_bloc.dart';
import 'package:seller_hub/logic/collection/collection_bloc.dart';
import 'package:seller_hub/logic/product/product_bloc.dart';
import 'package:seller_hub/logic/product/product_event.dart';
import 'package:seller_hub/logic/admin_user/customer_bloc.dart';
import 'package:seller_hub/logic/admin_user/seller_bloc.dart';
import 'package:seller_hub/logic/admin_user/admin_user_event.dart';
import 'package:seller_hub/logic/admin_user/admin_user_state.dart';
import 'package:seller_hub/presentation/dashboard/views/categories_view.dart';
import 'package:seller_hub/presentation/dashboard/views/catalog_view.dart';
import 'package:seller_hub/presentation/dashboard/views/collections_view.dart';
import 'package:seller_hub/presentation/dashboard/views/customer_profile_view.dart';
import 'package:seller_hub/presentation/dashboard/views/customers_view.dart';
import 'package:seller_hub/core/models/admin_user.dart';
import 'package:seller_hub/presentation/dashboard/views/operations_overview_view.dart';
import 'package:seller_hub/presentation/dashboard/views/order_detail_view.dart';
import 'package:seller_hub/presentation/dashboard/views/orders_view.dart';
import 'package:seller_hub/presentation/dashboard/views/product_catalog_view.dart';
import 'package:seller_hub/presentation/dashboard/views/product_details_view.dart';
import 'package:seller_hub/presentation/dashboard/views/seller_profile_view.dart';
import 'package:seller_hub/presentation/dashboard/views/sellers_view.dart';
import 'package:seller_hub/presentation/dashboard/views/users_view.dart';
import 'package:seller_hub/presentation/dashboard/widgets/add_product_dialog.dart';
import 'package:seller_hub/presentation/dashboard/widgets/dashboard_sidebar.dart';
import 'package:seller_hub/presentation/dashboard/widgets/dashboard_top_app_bar.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Primary Navigation: 0 = Dashboard / Operations, 1 = Products, 2 = Sellers, 3 = Orders
  int _selectedNavIndex = 0;

  // Active viewing/editing product state
  Product? _viewingProduct;
  bool _openInEditMode = false;

  // Multi-Tenant Sellers state
  final List<SellerProfile> _sellers = [];
  SellerProfile? _viewingSeller;
  String _productCatalogSellerFilter = 'All Sellers';

  // Orders management state
  final List<MarketplaceOrder> _orders = List.from(MockOrders.sampleOrders);
  MarketplaceOrder? _viewingOrder;

  // Customers management state
  AdminUser? _viewingCustomer;

  @override
  void initState() {
    super.initState();
    // Connect to WebSocket server to receive live changes
    WebSocketService().connect();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final pBloc = context.read<ProductBloc>();
        if (pBloc.state.allCatalogProducts.isEmpty) {
          pBloc.add(const FetchAllCatalogProducts());
        }
        final sellerBloc = context.read<SellerBloc>();
        if (sellerBloc.state.users.isEmpty && sellerBloc.state.status != AdminUserStatus.loading) {
          sellerBloc.add(const InitializeAdminUsers());
        }
        final customerBloc = context.read<CustomerBloc>();
        if (customerBloc.state.users.isEmpty && customerBloc.state.status != AdminUserStatus.loading) {
          customerBloc.add(const InitializeAdminUsers());
        }
      }
    });
  }

  @override
  void dispose() {
    WebSocketService().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 960;

    final backgroundColor = isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    final productBloc = context.watch<ProductBloc>();
    final products = productBloc.state.products;
    final allCatalogProducts = productBloc.state.allCatalogProducts.isNotEmpty
        ? productBloc.state.allCatalogProducts
        : products;
    final totalProductsCount = productBloc.state.totalProducts > 0
        ? productBloc.state.totalProducts
        : allCatalogProducts.length;

    final collectionBloc = context.watch<CollectionBloc>();
    final collectionsCount = collectionBloc.state.totalCollections;

    final categoryBloc = context.watch<CategoryBloc>();
    final categoriesCount = categoryBloc.state.totalCount;

    final sellerBloc = context.watch<SellerBloc>();
    final realSellers = sellerBloc.sellerProfiles;
    final displaySellers = [
      ...realSellers,
      ..._sellers.where((s) => !realSellers.any((r) => r.id == s.id)),
    ];
    final sellersCount = sellerBloc.state.totalCount > 0 ? sellerBloc.state.totalCount : displaySellers.length;

    final customerBloc = context.watch<CustomerBloc>();
    final customersCount = customerBloc.state.totalCount;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: isWide
          ? null
          : Drawer(
              backgroundColor: surfaceColor,
              child: DashboardSidebar(
                selectedIndex: _selectedNavIndex,
                onNavItemSelected: _onNavItemSelected,
                productsCount: totalProductsCount,
                collectionsCount: collectionsCount,
                categoriesCount: categoriesCount,
                sellersCount: sellersCount,
                customersCount: customersCount,
                ordersCount: _orders.length,
                isDrawer: true,
                onLogout: () => _handleLogout(context),
              ),
            ),
      body: Row(
        children: [
          // Desktop Persistent Compact Sidebar
          if (isWide)
            SizedBox(
              width: 224,
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(right: BorderSide(color: borderColor, width: 1)),
                ),
                child: DashboardSidebar(
                  selectedIndex: _selectedNavIndex,
                  onNavItemSelected: _onNavItemSelected,
                  productsCount: totalProductsCount,
                  collectionsCount: collectionsCount,
                  categoriesCount: categoriesCount,
                  sellersCount: sellersCount,
                  customersCount: customersCount,
                  ordersCount: _orders.length,
                  isDrawer: false,
                  onLogout: () => _handleLogout(context),
                ),
              ),
            ),

          // Main App Content Area
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                DashboardTopAppBar(
                  selectedNavIndex: _selectedNavIndex,
                  viewingProduct: _viewingProduct,
                  viewingSeller: _viewingSeller,
                  viewingOrder: _viewingOrder,
                  viewingCustomer: _viewingCustomer,
                  isWide: isWide,
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),

                // Active Section Body
                Expanded(
                  child: SelectionArea(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 32 : 16,
                        vertical: 24,
                      ),
                      child: _buildActiveContent(
                        isWide,
                        products,
                        allCatalogProducts,
                        totalProductsCount,
                        collectionsCount,
                        categoriesCount,
                        displaySellers,
                        sellersCount,
                        customersCount,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveContent(
    bool isWide,
    List<Product> products,
    List<Product> allProducts,
    int totalProductsCount,
    int collectionsCount,
    int categoriesCount,
    List<SellerProfile> sellers,
    int sellersCount,
    int customersCount,
  ) {
    if (_selectedNavIndex == 0) {
      return OperationsOverviewView(
        products: products,
        sellers: sellers,
        orders: _orders,
        onSelectOrder: (order) => setState(() => _viewingOrder = order),
        onSelectSeller: (seller) => setState(() => _viewingSeller = seller),
        onNavigateToProducts: () => setState(() {
          _selectedNavIndex = 1;
          _viewingProduct = null;
        }),
        onNavigateToSellers: () => setState(() {
          _selectedNavIndex = 4;
          _viewingSeller = null;
        }),
        onNavigateToOrders: () => setState(() {
          _selectedNavIndex = 5;
          _viewingOrder = null;
        }),
        onOpenAddProduct: () => _openAddProductDialog(context),
      );
    }

    // Nav Index 1, 2, 3: Unified Catalog (Products, Collections, Categories)
    if (_selectedNavIndex == 1 || _selectedNavIndex == 2 || _selectedNavIndex == 3) {
      Widget catalogChild;
      if (_selectedNavIndex == 1 && _viewingProduct != null) {
        catalogChild = ProductDetailsView(
          product: _viewingProduct!,
          startInEditMode: _openInEditMode,
          onBack: () => setState(() {
            _viewingProduct = null;
            _openInEditMode = false;
          }),
          onProductUpdated: (updated) {
            context.read<ProductBloc>().add(UpdateLocalProduct(updated));
            setState(() {
              _viewingProduct = updated;
            });
          },
        );
      } else if (_selectedNavIndex == 2) {
        catalogChild = CollectionsView(isWide: isWide);
      } else if (_selectedNavIndex == 3) {
        catalogChild = CategoriesView(isWide: isWide);
      } else {
        catalogChild = ProductCatalogView(
          products: allProducts,
          sellers: sellers,
          initialSellerFilter: _productCatalogSellerFilter,
          isWide: isWide,
          onOpenProductDetails: (product, {bool editMode = false}) {
            setState(() {
              _viewingProduct = product;
              _openInEditMode = editMode;
            });
          },
          onOpenAddProduct: () => _openAddProductDialog(context),
          onProductUpdated: (updated) {
            context.read<ProductBloc>().add(UpdateLocalProduct(updated));
          },
        );
      }

      return CatalogView(
        activeSubTabIndex: _selectedNavIndex - 1, // 0 = Products, 1 = Collections, 2 = Categories
        onSubTabChanged: (tabIndex) {
          setState(() {
            _selectedNavIndex = tabIndex + 1;
            _viewingProduct = null;
            _openInEditMode = false;
          });
        },
        productsCount: totalProductsCount,
        collectionsCount: collectionsCount,
        categoriesCount: categoriesCount,
        isWide: isWide,
        child: catalogChild,
      );
    }

    // Nav Index 4, 6: Unified Users (Sellers & Customers)
    if (_selectedNavIndex == 4 || _selectedNavIndex == 6) {
      Widget userChild;
      if (_selectedNavIndex == 4 && _viewingSeller != null) {
        userChild = SellerProfileView(
          seller: _viewingSeller!,
          allProducts: allProducts,
          onBack: () => setState(() => _viewingSeller = null),
          onSellerUpdated: (updated) {
            setState(() {
              final idx = _sellers.indexWhere((s) => s.id == updated.id);
              if (idx != -1) _sellers[idx] = updated;
              _viewingSeller = updated;
            });
          },
          onViewSellerProducts: (sellerTradeName) {
            setState(() {
              _selectedNavIndex = 1;
              _viewingSeller = null;
              _viewingProduct = null;
              _productCatalogSellerFilter = sellerTradeName;
            });
          },
        );
      } else if (_selectedNavIndex == 6 && _viewingCustomer != null) {
        userChild = CustomerProfileView(
          customer: _viewingCustomer!,
          allOrders: _orders,
          onBack: () => setState(() => _viewingCustomer = null),
          onCustomerUpdated: (updated) {
            setState(() => _viewingCustomer = updated);
          },
          onSelectOrder: (order) {
            setState(() {
              _selectedNavIndex = 5;
              _viewingCustomer = null;
              _viewingOrder = order;
            });
          },
        );
      } else if (_selectedNavIndex == 6) {
        userChild = CustomersView(
          isWide: isWide,
          onSelectCustomer: (customer) => setState(() => _viewingCustomer = customer),
        );
      } else {
        userChild = SellersView(
          sellers: sellers,
          products: allProducts,
          onSelectSeller: (seller) => setState(() => _viewingSeller = seller),
          onViewSellerProducts: (sellerTradeName) {
            setState(() {
              _selectedNavIndex = 1;
              _viewingSeller = null;
              _viewingProduct = null;
              _productCatalogSellerFilter = sellerTradeName;
            });
          },
          onSellerAdded: (newSeller) {
            setState(() {
              _sellers.insert(0, newSeller);
            });
          },
        );
      }

      return UsersView(
        activeSubTabIndex: _selectedNavIndex == 6 ? 1 : 0, // 0 = Sellers, 1 = Customers
        onSubTabChanged: (tabIndex) {
          setState(() {
            _selectedNavIndex = tabIndex == 1 ? 6 : 4;
            _viewingSeller = null;
            _viewingCustomer = null;
          });
        },
        sellersCount: sellersCount,
        customersCount: customersCount,
        isWide: isWide,
        child: userChild,
      );
    }

    // Nav Index 5: Orders Directory & Order Detail
    if (_selectedNavIndex == 5) {
      if (_viewingOrder != null) {
        return OrderDetailView(
          order: _viewingOrder!,
          onBack: () => setState(() => _viewingOrder = null),
          onOrderUpdated: (updated) {
            setState(() {
              final idx = _orders.indexWhere((o) => o.id == updated.id);
              if (idx != -1) _orders[idx] = updated;
              _viewingOrder = updated;
            });
          },
        );
      }

      return OrdersView(
        orders: _orders,
        onSelectOrder: (order) => setState(() => _viewingOrder = order),
      );
    }

    return const SizedBox.shrink();
  }

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedNavIndex = index;
      _viewingProduct = null;
      _openInEditMode = false;
      _viewingSeller = null;
      _viewingOrder = null;
      _viewingCustomer = null;
    });
  }

  void _openAddProductDialog(BuildContext context) {
    final activeSellerId = context.read<AuthBloc>().state.sellerId ?? '6ab4ada822033f1670582bda';
    showDialog(
      context: context,
      builder: (ctx) => AddProductDialog(
        sellerId: activeSellerId,
        onProductAdded: (newProduct) {
          context.read<ProductBloc>().add(CreateProduct(
            newProduct,
            onSuccess: (created) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Created "${created.title}" on backend for Seller $activeSellerId.',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: const Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.all(20),
                ),
              );
            },
            onError: (err) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to create product: $err',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.all(20),
                ),
              );
            },
          ));
        },
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    context.read<AuthBloc>().add(LogoutRequested());
    context.go(RouteNames.login);
  }
}
