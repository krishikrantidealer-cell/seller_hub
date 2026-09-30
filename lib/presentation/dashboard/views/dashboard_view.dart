import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/core/models/seller.dart';
import 'package:seller_hub/core/router/route_names.dart';
import 'package:seller_hub/logic/auth/auth_bloc.dart';
import 'package:seller_hub/logic/auth/auth_event.dart';
import 'package:seller_hub/presentation/dashboard/views/operations_overview_view.dart';
import 'package:seller_hub/presentation/dashboard/views/product_catalog_view.dart';
import 'package:seller_hub/presentation/dashboard/views/product_details_view.dart';
import 'package:seller_hub/presentation/dashboard/views/seller_profile_view.dart';
import 'package:seller_hub/presentation/dashboard/views/sellers_view.dart';
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

  // Primary Navigation: 0 = Dashboard / Operations, 1 = Products, 2 = Sellers
  int _selectedNavIndex = 0;

  // Product catalog state initialized with official 38-field schema models
  final List<Product> _products = List.from(Product.sampleProducts);
  Product? _viewingProduct;
  bool _openInEditMode = false;

  // Multi-Tenant Sellers state
  final List<SellerProfile> _sellers = List.from(SellerProfile.sampleSellers);
  SellerProfile? _viewingSeller;
  String _productCatalogSellerFilter = 'All Sellers';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 960;

    final backgroundColor = isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

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
                productsCount: _products.length,
                sellersCount: _sellers.length,
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
                  productsCount: _products.length,
                  sellersCount: _sellers.length,
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
                      child: _buildActiveContent(isWide),
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

  Widget _buildActiveContent(bool isWide) {
    if (_selectedNavIndex == 0) {
      return OperationsOverviewView(
        products: _products,
        onViewAllOrders: () {},
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
            setState(() {
              final idx = _products.indexWhere((p) => p.productCode == updated.productCode);
              if (idx != -1) _products[idx] = updated;
              _viewingProduct = updated;
            });
          },
        );
      }

      return ProductCatalogView(
        products: _products,
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
          setState(() {
            final idx = _products.indexWhere((p) => p.productCode == updated.productCode);
            if (idx != -1) _products[idx] = updated;
          });
        },
      );
    }

    // Nav Index 2: Sellers Directory & Profile
    if (_viewingSeller != null) {
      return SellerProfileView(
        seller: _viewingSeller!,
        allProducts: _products,
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
      products: _products,
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

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedNavIndex = index;
      _viewingProduct = null;
      _openInEditMode = false;
      _viewingSeller = null;
    });
  }

  void _openAddProductDialog(BuildContext context) {
    final activeSellerId = context.read<AuthBloc>().state.sellerId ?? '6ab4ada822033f1670582bda';
    showDialog(
      context: context,
      builder: (ctx) => AddProductDialog(
        sellerId: activeSellerId,
        onProductAdded: (newProduct) {
          setState(() {
            _products.insert(0, newProduct);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Added "${newProduct.title}" to catalog for Seller $activeSellerId.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(20),
            ),
          );
        },
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    context.read<AuthBloc>().add(LogoutRequested());
    context.go(RouteNames.login);
  }
}
