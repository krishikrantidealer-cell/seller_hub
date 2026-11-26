import 'dart:async';
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
import 'package:seller_hub/logic/auth/auth_state.dart';
import 'package:seller_hub/logic/category/category_bloc.dart';
import 'package:seller_hub/logic/collection/collection_bloc.dart';
import 'package:seller_hub/logic/order/order_bloc.dart';
import 'package:seller_hub/logic/order/order_event.dart';
import 'package:seller_hub/logic/order/order_state.dart';
import 'package:seller_hub/logic/product/product_bloc.dart';
import 'package:seller_hub/logic/product/product_event.dart';
import 'package:seller_hub/logic/admin_user/customer_bloc.dart';
import 'package:seller_hub/logic/admin_user/seller_bloc.dart';
import 'package:seller_hub/logic/admin_user/admin_user_event.dart';
import 'package:seller_hub/logic/admin_user/admin_user_state.dart';
import 'package:seller_hub/presentation/dashboard/views/access_management_view.dart';
import 'package:seller_hub/presentation/dashboard/views/admin_create_order_view.dart';
import 'package:seller_hub/presentation/dashboard/views/arrange_products_view.dart';
import 'package:seller_hub/presentation/dashboard/views/banners_view.dart';
import 'package:seller_hub/presentation/dashboard/views/categories_view.dart';
import 'package:seller_hub/presentation/dashboard/views/catalog_view.dart';
import 'package:seller_hub/presentation/dashboard/views/collections_view.dart';
import 'package:seller_hub/presentation/dashboard/views/customer_profile_view.dart';
import 'package:seller_hub/presentation/dashboard/views/sales_dashboard_view.dart';
import 'package:seller_hub/presentation/dashboard/views/customers_view.dart';
import 'package:seller_hub/core/models/admin_user.dart';
import 'package:seller_hub/domain/repositories/admin_user_repository.dart';
import 'package:seller_hub/presentation/dashboard/views/operations_overview_view.dart';
import 'package:seller_hub/presentation/dashboard/views/order_detail_view.dart';
import 'package:seller_hub/presentation/dashboard/views/orders_view.dart';
import 'package:seller_hub/presentation/dashboard/views/product_catalog_view.dart';
import 'package:seller_hub/presentation/dashboard/views/product_details_view.dart';
import 'package:seller_hub/presentation/dashboard/views/seller_profile_view.dart';
import 'package:seller_hub/presentation/dashboard/views/sellers_view.dart';
import 'package:seller_hub/presentation/dashboard/views/users_view.dart';
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
  int _catalogSubTabIndex = 0; // 0 = Products, 1 = Collections, 2 = Categories

  // Active viewing/editing product state
  Product? _viewingProduct;
  bool _openInEditMode = false;
  bool _isAddingProduct = false;

  // Multi-Tenant Sellers state
  final List<SellerProfile> _sellers = [];
  SellerProfile? _viewingSeller;
  String _productCatalogSellerFilter = 'All Sellers';

  // Orders management state (backed by OrderBloc)
  MarketplaceOrder? _viewingOrder;

  // Customers management state
  AdminUser? _viewingCustomer;
  bool _isCreatingOrderForCustomer = false;

  // Collapsible sidebar state (desktop)
  bool _isSidebarMinimized = false;
  bool _isSidebarHovered = false;

  @override
  void initState() {
    super.initState();
    // Connect to WebSocket server to receive live changes
    WebSocketService().connect();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrderBloc>().add(const LoadAdminOrders(page: 0, size: 50));
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

    final totalProductsCount = context.select<ProductBloc, int>((b) {
      if (b.state.totalProducts > 0) return b.state.totalProducts;
      if (b.state.allCatalogProducts.isNotEmpty) return b.state.allCatalogProducts.length;
      return b.state.products.length;
    });

    final collectionsCount = context.select<CollectionBloc, int>(
      (b) => b.state.totalCollections,
    );

    final categoriesCount = context.select<CategoryBloc, int>(
      (b) => b.state.totalCount,
    );

    final sellersCount = context.select<SellerBloc, int>((b) {
      final realSellers = b.sellerProfiles;
      if (b.state.totalCount > 0) return b.state.totalCount;
      return realSellers.length + _sellers.where((s) => !realSellers.any((r) => r.id == s.id)).length;
    });

    final customersCount = context.select<CustomerBloc, int>(
      (b) => b.state.totalCount,
    );

    final ordersCount = context.select<OrderBloc, int>(
      (b) => b.state.totalElements > 0 ? b.state.totalElements : b.state.orders.length,
    );

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState.status == AuthStatus.unauthenticated) {
          context.go(RouteNames.login);
        }
      },
      child: SelectionArea(
        child: Scaffold(
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
                ordersCount: ordersCount,
                isDrawer: true,
                onLogout: () => _handleLogout(context),
              ),
            ),
      body: Row(
        children: [
          // Desktop Persistent Compact & Minimizable Sidebar
          if (isWide)
            MouseRegion(
              onEnter: (_) {
                if (_isSidebarMinimized && !_isSidebarHovered) {
                  setState(() => _isSidebarHovered = true);
                }
              },
              onExit: (_) {
                if (_isSidebarHovered) {
                  setState(() => _isSidebarHovered = false);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                width: (_isSidebarMinimized && !_isSidebarHovered) ? 68 : 224,
                child: ClipRect(
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
                      ordersCount: ordersCount,
                      isDrawer: false,
                      isMinimized: _isSidebarMinimized && !_isSidebarHovered,
                      onToggleMinimize: () => setState(() {
                        _isSidebarMinimized = !_isSidebarMinimized;
                        _isSidebarHovered = false;
                      }),
                      onLogout: () => _handleLogout(context),
                    ),
                  ),
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

                // Active Section Body (with live RBAC route guard)
                Expanded(
                  child: BlocListener<AuthBloc, AuthState>(
                    listenWhen: (prev, curr) => prev.session?.permissions != curr.session?.permissions,
                    listener: (context, authState) {
                      final session = authState.session;
                      if (session == null || !session.isSalesAgent) return;
                      final fallback = _firstPermittedNavIndex(session);
                      if (!_isNavIndexPermitted(_selectedNavIndex, session) && fallback != null) {
                        setState(() {
                          _selectedNavIndex = fallback;
                          _viewingProduct = null;
                          _viewingSeller = null;
                          _viewingOrder = null;
                          _viewingCustomer = null;
                          _isCreatingOrderForCustomer = false;
                        });
                      }
                    },
                    child: Builder(
                      builder: (context) {
                        final session = context.watch<AuthBloc>().state.session;
                        if (session != null && session.isSalesAgent && !_isNavIndexPermitted(_selectedNavIndex, session)) {
                          final fallback = _firstPermittedNavIndex(session);
                          if (fallback == null) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'No workspace permissions assigned yet. Contact your Admin.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          }
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _selectedNavIndex != fallback) {
                              setState(() => _selectedNavIndex = fallback);
                            }
                          });
                        }
                        return (_selectedNavIndex >= 1 && _selectedNavIndex <= 3)
                            ? _buildCatalogSection(
                                isWide: isWide,
                                totalProductsCount: totalProductsCount,
                                collectionsCount: collectionsCount,
                                categoriesCount: categoriesCount,
                              )
                            : SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 32 : 16,
                                  vertical: 24,
                                ),
                                child: _buildActiveContent(
                                  isWide,
                                  customersCount: customersCount,
                                ),
                              );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
  );
  }

  Widget _buildCatalogSection({
    required bool isWide,
    required int totalProductsCount,
    required int collectionsCount,
    required int categoriesCount,
  }) {
    Widget? detailOverlay;
    if (_selectedNavIndex == 1 && _viewingProduct != null) {
      detailOverlay = ProductDetailsView(
        key: ValueKey('view_${_viewingProduct!.id}_$_openInEditMode'),
        product: _viewingProduct!,
        startInEditMode: _openInEditMode,
        onBack: () => setState(() {
          _viewingProduct = null;
          _openInEditMode = false;
        }),
        onProductUpdated: (updated) {
          final prevProduct = _viewingProduct;
          final completer = Completer<bool>();
          context.read<ProductBloc>().add(UpdateProduct(
            updated,
            onSuccess: (savedProduct) async {
              var finalProduct = savedProduct;
              final desiredIds = <String>{
                ...updated.collectionIds,
                ...updated.subCollectionIds,
              };
              final existingIds = <String>{
                ...(prevProduct?.assignedCollections ?? const <String>[]),
                ...(prevProduct?.collectionIds ?? const <String>[]),
                ...(prevProduct?.subCollectionIds ?? const <String>[]),
              };
              final collectionsChanged =
                  desiredIds.length != existingIds.length ||
                  !desiredIds.containsAll(existingIds);
              if (collectionsChanged) {
                final colCompleter = Completer<Product?>();
                context.read<ProductBloc>().add(AssignProductCollections(
                  productId: savedProduct.id,
                  collectionIds: updated.collectionIds,
                  subCollectionIds: updated.subCollectionIds,
                  onSuccess: (withCols) {
                    if (!colCompleter.isCompleted) colCompleter.complete(withCols);
                  },
                  onError: (_) {
                    if (!colCompleter.isCompleted) colCompleter.complete(null);
                  },
                ));
                final assigned = await colCompleter.future;
                if (assigned != null) finalProduct = assigned;
              }
              if (mounted) {
                setState(() {
                  _viewingProduct = finalProduct;
                });
              }
              if (!completer.isCompleted) completer.complete(true);
            },
            onError: (err) {
              if (mounted) {
                if (prevProduct != null) {
                  setState(() {
                    _viewingProduct = prevProduct;
                  });
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update product on server: $err'),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              if (!completer.isCompleted) completer.complete(false);
            },
          ));
          return completer.future;
        },
      );
    } else if (_selectedNavIndex == 1 && _isAddingProduct) {
      detailOverlay = ProductDetailsView(
        key: const ValueKey('create_product'),
        product: Product(
          id: '',
          title: '',
          sellerId: '',
          sellerName: '',
          vendor: '',
          sku: '',
          productCode: '',
          hsnCode: '',
          description: '',
          images: [],
        ),
        isCreateMode: true,
        startInEditMode: true,
        onBack: () => setState(() => _isAddingProduct = false),
        onProductCreated: (newProduct, [pendingImages]) {
          final completer = Completer<bool>();
          final productBloc = context.read<ProductBloc>();
          productBloc.add(CreateProduct(
            newProduct,
            onSuccess: (created) async {
              var finalProduct = created;
              String? imageUploadError;
              if (pendingImages != null && pendingImages.isNotEmpty) {
                final imgCompleter = Completer<Product?>();
                productBloc.add(UploadProductImages(
                  productId: created.id,
                  filesBytes: pendingImages.map((e) => e.bytes).toList(),
                  fileNames: pendingImages.map((e) => e.name).toList(),
                  onSuccess: (withImages) {
                    if (!imgCompleter.isCompleted) imgCompleter.complete(withImages);
                  },
                  onError: (err) {
                    imageUploadError = err;
                    if (!imgCompleter.isCompleted) imgCompleter.complete(null);
                  },
                ));
                final uploaded = await imgCompleter.future;
                if (uploaded != null) finalProduct = uploaded;
              }
              if (newProduct.collectionIds.isNotEmpty || newProduct.subCollectionIds.isNotEmpty) {
                final colCompleter = Completer<Product?>();
                productBloc.add(AssignProductCollections(
                  productId: finalProduct.id,
                  collectionIds: newProduct.collectionIds,
                  subCollectionIds: newProduct.subCollectionIds,
                  onSuccess: (withCols) {
                    if (!colCompleter.isCompleted) colCompleter.complete(withCols);
                  },
                  onError: (_) {
                    if (!colCompleter.isCompleted) colCompleter.complete(null);
                  },
                ));
                final assigned = await colCompleter.future;
                if (assigned != null) finalProduct = assigned;
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      imageUploadError != null
                          ? 'Created "${finalProduct.title}", but image upload failed: $imageUploadError'
                          : 'Created "${finalProduct.title}" successfully!',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: imageUploadError != null
                        ? const Color(0xFFD97706)
                        : const Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    margin: const EdgeInsets.all(20),
                  ),
                );
                setState(() {
                  _isAddingProduct = false;
                  _viewingProduct = finalProduct;
                  _openInEditMode = false;
                });
              }
              if (!completer.isCompleted) completer.complete(true);
            },
            onError: (err) {
              if (mounted) {
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
              }
              if (!completer.isCompleted) completer.complete(false);
            },
          ));
          return completer.future;
        },
      );
    }

    return CatalogView(
      activeSubTabIndex: _catalogSubTabIndex, // 0 = Products, 1 = Collections, 2 = Categories, 3 = Technical Names
      onSubTabChanged: (tabIndex) {
        setState(() {
          _catalogSubTabIndex = tabIndex;
          if (tabIndex <= 2) {
            _selectedNavIndex = tabIndex + 1;
          }
          _viewingProduct = null;
          _openInEditMode = false;
          _isAddingProduct = false;
        });
      },
      productsCount: totalProductsCount,
      collectionsCount: collectionsCount,
      categoriesCount: categoriesCount,
      isWide: isWide,
      detailOverlay: detailOverlay,
      productsBuilder: (ctx) {
        final pState = ctx.read<ProductBloc>().state;
        final allProducts = pState.allCatalogProducts.isNotEmpty
            ? pState.allCatalogProducts
            : pState.products;
        final realSellers = ctx.read<SellerBloc>().sellerProfiles;
        final sellers = [
          ...realSellers,
          ..._sellers.where((s) => !realSellers.any((r) => r.id == s.id)),
        ];
        final rootCategories = ctx.read<CategoryBloc>().state.rootCategories;
        return ProductCatalogView(
          products: allProducts,
          sellers: sellers,
          categories: rootCategories,
          initialSellerFilter: _productCatalogSellerFilter,
          isWide: isWide,
          onOpenProductDetails: (product, {bool editMode = false}) {
            setState(() {
              _viewingProduct = product;
              _openInEditMode = editMode;
            });
          },
          onOpenAddProduct: _openAddProductScreen,
          onProductUpdated: (updated) {
            context.read<ProductBloc>().add(UpdateProduct(updated));
          },
        );
      },
      collectionsBuilder: (_) => CollectionsView(isWide: isWide),
      categoriesBuilder: (_) => CategoriesView(isWide: isWide),
      bannersBuilder: (_) => BannersView(isWide: isWide),
      arrangeBuilder: (_) => ArrangeProductsView(isWide: isWide),
    );
  }

  Widget _buildActiveContent(bool isWide, {required int customersCount}) {
    final pState = context.watch<ProductBloc>().state;
    final products = pState.products;
    final allProducts = pState.allCatalogProducts.isNotEmpty ? pState.allCatalogProducts : products;

    final sellerBloc = context.watch<SellerBloc>();
    final realSellers = sellerBloc.sellerProfiles;
    final sellers = [
      ...realSellers,
      ..._sellers.where((s) => !realSellers.any((r) => r.id == s.id)),
    ];
    final sellersCount = sellerBloc.state.totalCount > 0 ? sellerBloc.state.totalCount : sellers.length;

    if (_selectedNavIndex == 0) {
      final session = context.watch<AuthBloc>().state.session;
      final ordersList = context.watch<OrderBloc>().state.orders;
      if (session != null && session.isSalesAgent) {
        return SalesDashboardView(
          session: session,
          orders: ordersList,
          customersCount: customersCount,
          onSelectOrder: (order) => setState(() {
            _selectedNavIndex = 5;
            _viewingOrder = order;
          }),
          onNavigateToOrders: () => setState(() {
            _selectedNavIndex = 5;
            _viewingOrder = null;
          }),
          onNavigateToCustomers: () => setState(() {
            _selectedNavIndex = 6;
            _viewingCustomer = null;
            _isCreatingOrderForCustomer = false;
          }),
        );
      }
      return OperationsOverviewView(
        products: products,
        sellers: sellers,
        orders: ordersList,
        onSelectOrder: (order) => setState(() {
          _selectedNavIndex = 5;
          _viewingOrder = order;
        }),
        onSelectSeller: (seller) => setState(() {
          _selectedNavIndex = 4;
          _viewingSeller = seller;
        }),
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
        onOpenAddProduct: _openAddProductScreen,
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
      } else if (_selectedNavIndex == 6 && _viewingCustomer != null && _isCreatingOrderForCustomer) {
        userChild = AdminCreateOrderView(
          customer: _viewingCustomer!,
          onBack: () => setState(() => _isCreatingOrderForCustomer = false),
          onOrderCreated: (created) {
            setState(() => _isCreatingOrderForCustomer = false);
            if (created == null) return;
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF059669),
                content: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order ${created.orderNumber} created successfully!',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        setState(() {
                          _selectedNavIndex = 5;
                          _viewingCustomer = null;
                          _isCreatingOrderForCustomer = false;
                          _viewingOrder = created;
                        });
                      },
                      child: const Text(
                        'View Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else if (_selectedNavIndex == 6 && _viewingCustomer != null) {
        userChild = CustomerProfileView(
          key: ValueKey(_viewingCustomer!.id),
          customer: _viewingCustomer!,
          allOrders: context.watch<OrderBloc>().state.orders,
          onBack: () => setState(() {
            _viewingCustomer = null;
            _isCreatingOrderForCustomer = false;
          }),
          onCustomerUpdated: (updated) {
            setState(() => _viewingCustomer = updated);
          },
          onCreateOrder: () => setState(() => _isCreatingOrderForCustomer = true),
          onSelectOrder: (order) {
            setState(() {
              _selectedNavIndex = 5;
              _viewingCustomer = null;
              _isCreatingOrderForCustomer = false;
              _viewingOrder = order;
            });
          },
        );
      } else if (_selectedNavIndex == 6) {
        userChild = CustomersView(
          isWide: isWide,
          allOrders: context.watch<OrderBloc>().state.orders,
          onSelectCustomer: (customer) => setState(() {
            _viewingCustomer = customer;
            _isCreatingOrderForCustomer = false;
          }),
          onCreateOrderForCustomer: (customer) => setState(() {
            _viewingCustomer = customer;
            _isCreatingOrderForCustomer = true;
          }),
          onOpenCreateCustomer: () => setState(() {
            _viewingCustomer = AdminUser.emptyCustomer();
            _isCreatingOrderForCustomer = false;
          }),
        );
      } else {
        userChild = SellersView(
          sellers: sellers,
          products: allProducts,
          onSelectSeller: (seller) => setState(() => _viewingSeller = seller),
          onOpenCreateSeller: () => setState(() => _viewingSeller = SellerProfile.empty()),
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
            _isCreatingOrderForCustomer = false;
          });
        },
        sellersCount: sellersCount,
        customersCount: customersCount,
        isWide: isWide,
        child: userChild,
      );
    }

    // Nav Index 7: Admin-Only Access Management
    if (_selectedNavIndex == 7) {
      final isAdmin = context.read<AuthBloc>().state.session?.isAdmin ?? false;
      if (isAdmin) {
        return const AccessManagementView();
      }
    }

    // Nav Index 5: Orders Directory & Order Detail
    if (_selectedNavIndex == 5) {
      final orderState = context.watch<OrderBloc>().state;
      final orders = orderState.orders;
      if (_viewingOrder != null) {
        final liveViewing = orders.where((o) => o.id == _viewingOrder!.id).firstOrNull ?? _viewingOrder!;
        return OrderDetailView(
          order: liveViewing,
          onBack: () => setState(() => _viewingOrder = null),
          onOrderUpdated: (updated) {
            context.read<OrderBloc>().add(UpdateAdminOrderLocal(updated));
            setState(() => _viewingOrder = updated);
          },
        );
      }

      return OrdersView(
        orders: orders,
        isLoading: orderState.status == AdminOrderStatus.loading,
        errorMessage: orderState.errorMessage,
        onRetry: () => context.read<OrderBloc>().add(const LoadAdminOrders(page: 0, size: 50, isRefresh: true)),
        hasMore: orderState.hasMore,
        isLoadingMore: orderState.isLoadingMore,
        onLoadMore: () => context.read<OrderBloc>().add(const LoadMoreAdminOrders()),
        onSelectOrder: (order) => setState(() => _viewingOrder = order),
        onSelectCustomer: (order) => _openCustomerProfileForOrder(order),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _openCustomerProfileForOrder(MarketplaceOrder order) async {
    String normalizePhone(String raw) {
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 10) return digits.substring(digits.length - 10);
      return digits;
    }

    AdminUser? findMatch(List<AdminUser> list) {
      if (order.customerId.isNotEmpty) {
        final byId = list.where((c) => c.id == order.customerId).firstOrNull;
        if (byId != null) return byId;
      }
      final orderPhone = normalizePhone(order.shippingAddress.phone);
      if (orderPhone.isNotEmpty) {
        final byPhone = list.where((c) => normalizePhone(c.phoneNumber) == orderPhone).firstOrNull;
        if (byPhone != null) return byPhone;
      }
      return null;
    }

    final customerBloc = context.read<CustomerBloc>();
    AdminUser? match = findMatch(customerBloc.state.users);

    if (match == null) {
      try {
        final repo = context.read<AdminUserRepository>();
        final orderPhone = normalizePhone(order.shippingAddress.phone);
        final page = await repo.getUsers(
          role: 'ROLE_CUSTOMER',
          page: 0,
          size: 100,
          q: orderPhone.isNotEmpty ? orderPhone : null,
        );
        match = findMatch(page.content);
        if (match == null && orderPhone.isNotEmpty) {
          final allPage = await repo.getUsers(role: 'ROLE_CUSTOMER', page: 0, size: 100);
          match = findMatch(allPage.content);
        }
        if (customerBloc.state.users.isEmpty) {
          customerBloc.add(const FetchAdminUsers());
        }
      } catch (_) {}
    }

    if (!mounted) return;
    if (match != null) {
      setState(() {
        _selectedNavIndex = 6;
        _viewingOrder = null;
        _viewingCustomer = match;
        _isCreatingOrderForCustomer = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer profile not found in directory.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isNavIndexPermitted(int index, dynamic session) {
    if (session == null || session.isAdmin == true) return true;
    switch (index) {
      case 0:
        return session.hasPermission('DASHBOARD_VIEW');
      case 1:
      case 2:
      case 3:
        return session.hasAnyPermission(['CATALOG_VIEW', 'CATALOG_MANAGE']);
      case 4:
        return session.hasPermission('USERS_SELLERS_VIEW');
      case 6:
        return session.hasAnyPermission(['USERS_CUSTOMERS_VIEW', 'USERS_CUSTOMERS_MANAGE']);
      case 5:
        return session.hasAnyPermission(['ORDERS_VIEW', 'ORDERS_CREATE', 'ORDERS_MANAGE']);
      case 7:
        return false;
      default:
        return false;
    }
  }

  int? _firstPermittedNavIndex(dynamic session) {
    for (final idx in const [0, 5, 6, 4, 1]) {
      if (_isNavIndexPermitted(idx, session)) return idx;
    }
    return null;
  }

  void _openAddProductScreen() {
    setState(() {
      _selectedNavIndex = 1;
      _catalogSubTabIndex = 0;
      _viewingProduct = null;
      _openInEditMode = false;
      _isAddingProduct = true;
    });
  }

  void _onNavItemSelected(int index) {
    final session = context.read<AuthBloc>().state.session;
    var targetIndex = index;
    if (targetIndex == 4 && session != null && !session.hasPermission('USERS_SELLERS_VIEW')) {
      targetIndex = 6;
    }
    if (targetIndex == 5) {
      context.read<OrderBloc>().add(const LoadAdminOrders(page: 0, size: 50, isRefresh: true));
    }
    setState(() {
      _selectedNavIndex = targetIndex;
      if (targetIndex >= 1 && targetIndex <= 3) {
        _catalogSubTabIndex = targetIndex - 1;
      }
      _viewingProduct = null;
      _openInEditMode = false;
      _isAddingProduct = false;
      _viewingSeller = null;
      _viewingOrder = null;
      _viewingCustomer = null;
      _isCreatingOrderForCustomer = false;
    });
  }



  void _handleLogout(BuildContext context) {
    context.read<AuthBloc>().add(LogoutRequested());
    context.go(RouteNames.login);
  }
}
