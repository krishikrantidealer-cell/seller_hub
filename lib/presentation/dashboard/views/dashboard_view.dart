import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/order.dart';
import '../../../core/models/product.dart';
import '../../../core/models/seller.dart';
import '../../../core/router/route_names.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/seller_catalog/seller_catalog_bloc.dart';
import '../../../logic/seller_catalog/seller_catalog_event.dart';
import '../../../logic/seller_catalog/seller_catalog_state.dart';
import '../../../logic/seller_orders/seller_order_bloc.dart';
import '../../../logic/seller_orders/seller_order_event.dart';
import '../../../logic/seller_orders/seller_order_state.dart';
import 'operations_overview_view.dart';
import 'order_detail_view.dart';
import 'orders_view.dart';
import 'product_catalog_view.dart';
import 'product_details_view.dart';
import 'seller_profile_view.dart';
import 'sellers_view.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/dashboard_sidebar.dart';
import '../widgets/dashboard_top_app_bar.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Primary Navigation: 0 = Dashboard / Operations, 1 = Products, 2 = Sellers, 3 = Orders
  int _selectedNavIndex = 0;

  Product? _viewingProduct;
  bool _openInEditMode = false;

  // Multi-Tenant Sellers state
  final List<SellerProfile> _sellers = List.from(SellerProfile.sampleSellers);
  SellerProfile? _viewingSeller;
  String _productCatalogSellerFilter = 'All Sellers';

  MarketplaceOrder? _viewingOrder;

  @override
  void initState() {
    super.initState();
    // Dispatch initial fetches if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final catalogState = context.read<SellerCatalogBloc>().state;
        if (catalogState is SellerCatalogInitial) {
          context.read<SellerCatalogBloc>().add(const FetchSellerProductsEvent());
        }
        final orderState = context.read<SellerOrderBloc>().state;
        if (orderState is SellerOrderInitial) {
          context.read<SellerOrderBloc>().add(const FetchSellerOrdersEvent());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 960;

    final backgroundColor = isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    return BlocConsumer<SellerCatalogBloc, SellerCatalogState>(
      listener: (context, catalogState) {
        if (catalogState is SellerCatalogActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                catalogState.message,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(20),
            ),
          );
        } else if (catalogState is SellerCatalogError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                catalogState.message,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(20),
            ),
          );
        }
      },
      builder: (context, catalogState) {
        return BlocBuilder<SellerOrderBloc, SellerOrderState>(
          builder: (context, orderState) {
            final products = catalogState.products.isNotEmpty
                ? catalogState.products
                : List<Product>.from(Product.sampleProducts);
            final orders = orderState.orders.isNotEmpty
                ? orderState.orders
                : List<MarketplaceOrder>.from(MockOrders.sampleOrders);

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
                        productsCount: products.length,
                        sellersCount: _sellers.length,
                        ordersCount: orders.length,
                        isDrawer: true,
                        onLogout: () => _handleLogout(context),
                      ),
                    ),
              body: Row(
                children: [
                  // Desktop Persistent Sidebar
                  if (isWide)
                    SizedBox(
                      width: 270,
                      child: Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          border: Border(right: BorderSide(color: borderColor, width: 1)),
                        ),
                        child: DashboardSidebar(
                          selectedIndex: _selectedNavIndex,
                          onNavItemSelected: _onNavItemSelected,
                          productsCount: products.length,
                          sellersCount: _sellers.length,
                          ordersCount: orders.length,
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
                          isWide: isWide,
                          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),

                        // Active Section Body
                        Expanded(
                          child: SelectionArea(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: isWide ? 32 : 16,
                                vertical: 24,
                              ),
                              child: _buildActiveContent(isWide, products, orders),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveContent(bool isWide, List<Product> products, List<MarketplaceOrder> orders) {
    if (_selectedNavIndex == 0) {
      return OperationsOverviewView(
        products: products,
        sellers: _sellers,
        orders: orders,
        onSelectOrder: (order) => setState(() => _viewingOrder = order),
        onSelectSeller: (seller) => setState(() => _viewingSeller = seller),
        onNavigateToProducts: () => setState(() {
          _selectedNavIndex = 1;
          _viewingProduct = null;
        }),
        onNavigateToSellers: () => setState(() {
          _selectedNavIndex = 2;
          _viewingSeller = null;
        }),
        onNavigateToOrders: () => setState(() {
          _selectedNavIndex = 3;
          _viewingOrder = null;
        }),
        onOpenAddProduct: () => _openAddProductDialog(context),
      );
    }

    if (_selectedNavIndex == 1) {
      if (_viewingProduct != null) {
        return ProductDetailsView(
          product: _viewingProduct!,
          startInEditMode: _openInEditMode,
          onBack: () => setState(() {
            _viewingProduct = null;
            _openInEditMode = false;
          }),
          onProductUpdated: (updated) {
            context.read<SellerCatalogBloc>().add(UpdateProductListingEvent(updated));
            setState(() {
              _viewingProduct = updated;
            });
          },
        );
      }

      return ProductCatalogView(
        products: products,
        sellers: _sellers,
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
          context.read<SellerCatalogBloc>().add(UpdateProductListingEvent(updated));
        },
      );
    }

    // Nav Index 2: Sellers Directory & Profile
    if (_selectedNavIndex == 2) {
      if (_viewingSeller != null) {
        return SellerProfileView(
          seller: _viewingSeller!,
          allProducts: products,
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
      }

      return SellersView(
        sellers: _sellers,
        products: products,
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

    // Nav Index 3: Orders Directory & Order Detail
    if (_viewingOrder != null) {
      return OrderDetailView(
        order: _viewingOrder!,
        onBack: () => setState(() => _viewingOrder = null),
        onOrderUpdated: (updated) {
          context.read<SellerOrderBloc>().add(UpdateLocalSellerOrderEvent(updated));
          setState(() {
            _viewingOrder = updated;
          });
        },
      );
    }

    return OrdersView(
      orders: orders,
      onSelectOrder: (order) => setState(() => _viewingOrder = order),
    );
  }

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedNavIndex = index;
      _viewingProduct = null;
      _openInEditMode = false;
      _viewingSeller = null;
      _viewingOrder = null;
    });
  }

  void _openAddProductDialog(BuildContext context) {
    final activeSellerId = context.read<AuthBloc>().state.sellerId ?? '6ab4ada822033f1670582bda';
    showDialog(
      context: context,
      builder: (ctx) => AddProductDialog(
        sellerId: activeSellerId,
        onProductAdded: (newProduct) {
          context.read<SellerCatalogBloc>().add(SubmitProductListingEvent(newProduct));
        },
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    context.read<AuthBloc>().add(LogoutRequested());
    context.go(RouteNames.login);
  }
}
