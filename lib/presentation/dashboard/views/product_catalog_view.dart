import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/core/models/seller.dart';
import 'package:seller_hub/presentation/dashboard/widgets/pagination_footer.dart';
import 'package:seller_hub/presentation/dashboard/widgets/product_mobile_card.dart';
import 'package:seller_hub/presentation/dashboard/widgets/product_table_row.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seller_hub/core/models/category.dart';
import 'package:seller_hub/logic/category/category_bloc.dart';
import 'package:seller_hub/logic/category/category_state.dart';
import 'package:seller_hub/logic/product/product_bloc.dart';
import 'package:seller_hub/logic/product/product_event.dart';
import 'package:seller_hub/logic/product/product_state.dart';
import 'package:seller_hub/logic/admin_user/seller_bloc.dart';
import 'package:seller_hub/logic/admin_user/admin_user_event.dart';
import 'package:seller_hub/logic/admin_user/admin_user_state.dart';

class _SellerFilterOption {
  final String key;
  final String label;
  final String? sellerId;
  final int productCount;

  const _SellerFilterOption({
    required this.key,
    required this.label,
    this.sellerId,
    required this.productCount,
  });
}

class ProductCatalogView extends StatefulWidget {
  final List<Product> products;
  final List<SellerProfile> sellers;
  final List<CategoryItem>? categories;
  final String initialSellerFilter;
  final bool isWide;
  final void Function(Product product, {bool editMode}) onOpenProductDetails;
  final VoidCallback onOpenAddProduct;
  final ValueChanged<Product>? onProductUpdated;

  const ProductCatalogView({
    super.key,
    required this.products,
    required this.sellers,
    this.categories,
    this.initialSellerFilter = 'All Sellers',
    required this.isWide,
    required this.onOpenProductDetails,
    required this.onOpenAddProduct,
    this.onProductUpdated,
  });

  @override
  State<ProductCatalogView> createState() => _ProductCatalogViewState();
}

class _ProductCatalogViewState extends State<ProductCatalogView> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedSellerFilter;
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';
  String _selectedStockFilter = 'All Stock';
  String _selectedAvailabilityFilter = 'All Status';

  // Multi-Selection & Sorting State
  final Set<String> _selectedProductCodes = {};
  String _sortColumn = 'default';
  bool _sortAscending = true;

  // Pagination State
  int _currentPage = 1;
  int _rowsPerPage = 20;
  final List<int> _rowsPerPageOptions = const [5, 10, 20, 50, 100];

  List<CategoryItem> _resolveLevel0Categories(CategoryState? catState) {
    if (widget.categories != null && widget.categories!.isNotEmpty) {
      final roots = widget.categories!
          .where((c) => c.level == 0 || c.parentId == null || c.parentId!.isEmpty)
          .toList();
      if (roots.isNotEmpty) return roots;
      return widget.categories!;
    }
    if (catState != null && catState.rootCategories.isNotEmpty) {
      return catState.rootCategories;
    }
    if (catState != null && catState.allCategories.isNotEmpty) {
      final roots = catState.allCategories
          .where((c) => c.level == 0 || c.parentId == null || c.parentId!.isEmpty)
          .toList();
      if (roots.isNotEmpty) return roots;
    }
    return const [];
  }

  List<String> _buildCategoryFilterOptions(List<CategoryItem> level0Categories) {
    final list = <String>['All'];
    if (level0Categories.isNotEmpty) {
      for (final c in level0Categories) {
        final name = c.name.trim();
        if (name.isNotEmpty && !list.contains(name)) {
          list.add(name);
        }
      }
    } else {
      for (final p in widget.products) {
        final cat = p.resolvedCategory.trim();
        if (cat.isNotEmpty && !list.contains(cat)) {
          list.add(cat);
        }
      }
      for (final fallback in const [
        'Insecticides',
        'Seeds',
        'Fertilizers',
        'Fungicides',
        'Bio Stimulants',
        'Herbicides',
      ]) {
        if (!list.contains(fallback)) {
          list.add(fallback);
        }
      }
    }
    return list;
  }

  bool _matchesCategory(
    Product p,
    String selectedFilter,
    List<CategoryItem> level0Categories,
    Map<String, CategoryItem> categoryById,
  ) {
    if (selectedFilter == 'All') return true;

    final filterLower = selectedFilter.toLowerCase().trim();

    // 1. Direct name match on product.category or resolvedCategory
    if (p.category.trim().toLowerCase() == filterLower) return true;
    if (p.resolvedCategory.trim().toLowerCase() == filterLower) return true;

    // 2. Check if selected filter corresponds to a Level 0 category item
    final root = level0Categories
        .where((c) => c.name.trim().toLowerCase() == filterLower)
        .firstOrNull;
    if (root != null) {
      // Direct ID match
      if (p.categoryId.isNotEmpty && p.categoryId == root.id) return true;

      // Check if p.categoryId is in root's hierarchy
      if (p.categoryId.isNotEmpty) {
        for (final child in root.children) {
          if (child.id == p.categoryId ||
              child.name.trim().toLowerCase() == p.category.trim().toLowerCase()) {
            return true;
          }
          for (final leaf in child.children) {
            if (leaf.id == p.categoryId ||
                leaf.name.trim().toLowerCase() == p.category.trim().toLowerCase()) {
              return true;
            }
          }
        }

        final item = categoryById[p.categoryId];
        if (item != null) {
          if (item.parentId == root.id) return true;
          final parent = categoryById[item.parentId];
          if (parent != null && parent.parentId == root.id) return true;
        }
      }

      // Keyword / title / description match
      final searchable = '${p.title} ${p.category} ${p.description}'.toLowerCase();
      if (root.name.length >= 4 && searchable.contains(root.name.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _selectedSellerFilter = widget.initialSellerFilter;
    _searchController.addListener(() {
      final q = _searchController.text.trim();
      if (_searchQuery != q) {
        setState(() {
          _searchQuery = q;
          _currentPage = 1;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final pBloc = context.read<ProductBloc>();
          if (pBloc.state.allCatalogProducts.isEmpty) {
            pBloc.add(const FetchAllCatalogProducts());
          }
          final sellerBloc = context.read<SellerBloc>();
          if (sellerBloc.state.users.isEmpty && sellerBloc.state.status != AdminUserStatus.loading) {
            sellerBloc.add(const InitializeAdminUsers());
          }
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProductCatalogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSellerFilter != widget.initialSellerFilter) {
      setState(() {
        _selectedSellerFilter = widget.initialSellerFilter;
        _currentPage = 1;
      });
    }
  }

  List<SellerProfile> _getActiveSellers([SellerBloc? sellerBloc]) {
    if (sellerBloc != null && sellerBloc.sellerProfiles.isNotEmpty) {
      return sellerBloc.sellerProfiles;
    }
    return widget.sellers;
  }

  String _resolveSellerName(Product p, [List<SellerProfile>? sellersList]) {
    final sellers = sellersList ?? _getActiveSellers();
    // 1. Primary match: lookup by sellerId or sellerCode in active real sellers
    if (p.sellerId.isNotEmpty) {
      for (final s in sellers) {
        if (s.id == p.sellerId || s.sellerCode == p.sellerId) {
          if (s.tradeName.trim().isNotEmpty) return s.tradeName.trim();
          if (s.companyName.trim().isNotEmpty) return s.companyName.trim();
        }
      }
    }
    // 2. Secondary match: sellerName or vendor name from product if available and meaningful
    final sellerNameCandidate = p.sellerName.isNotEmpty ? p.sellerName : p.vendor;
    if (sellerNameCandidate.isNotEmpty && sellerNameCandidate != 'TEST DATA - temporary placeholder') {
      return sellerNameCandidate;
    }
    // 3. Fallback: formatted seller ID or Unassigned
    if (p.sellerId.isNotEmpty) {
      final snippet = p.sellerId.length > 8 ? p.sellerId.substring(0, 8) : p.sellerId;
      return 'Seller ($snippet)';
    }
    return 'Unassigned';
  }

  String _resolveSellerPhoneNumber(Product p, [List<SellerProfile>? sellersList, SellerBloc? sellerBloc]) {
    if (p.sellerId.isEmpty) return '';

    // 1. Primary match: lookup in active sellers list
    final sellers = sellersList ?? _getActiveSellers();
    for (final s in sellers) {
      if (s.id == p.sellerId || s.sellerCode == p.sellerId) {
        if (s.phoneNumber.trim().isNotEmpty) return s.phoneNumber.trim();
      }
    }

    // 2. Secondary match: lookup in SellerBloc user accounts
    if (sellerBloc != null) {
      for (final u in sellerBloc.state.users) {
        if (u.id == p.sellerId && u.phoneNumber.trim().isNotEmpty) {
          return u.phoneNumber.trim();
        }
      }
    }

    // 3. Fallback: widget.sellers
    for (final s in widget.sellers) {
      if (s.id == p.sellerId && s.phoneNumber.trim().isNotEmpty) {
        return s.phoneNumber.trim();
      }
    }

    return '';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'insecticides':
        return const Color(0xFFD97706);
      case 'fertilizers':
        return const Color(0xFF059669);
      case 'seeds':
        return const Color(0xFF0284C7);
      case 'fungicides':
        return const Color(0xFF7C3AED);
      case 'bio stimulants':
        return const Color(0xFF0D9488);
      case 'herbicides':
        return const Color(0xFFE11D48);
      default:
        return const Color(0xFF059669);
    }
  }

  int _countProductsForSeller(String? sellerId, String sellerName, List<Product> catalog) {
    if (sellerId == null || sellerId.isEmpty) {
      return catalog.length;
    }
    return catalog.where((p) {
      if (p.sellerId.isNotEmpty && p.sellerId == sellerId) return true;
      if (p.sellerName.isNotEmpty && p.sellerName.trim().toLowerCase() == sellerName.trim().toLowerCase()) return true;
      if (p.vendor.isNotEmpty && p.vendor.trim().toLowerCase() == sellerName.trim().toLowerCase()) return true;
      return false;
    }).length;
  }

  List<_SellerFilterOption> _buildSellerOptions(
    List<SellerProfile> activeSellers,
    List<Product> catalog,
    int totalCount,
  ) {
    final list = <_SellerFilterOption>[
      _SellerFilterOption(
        key: 'All Sellers',
        label: 'All Sellers',
        productCount: totalCount,
      ),
    ];
    final seenKeys = <String>{'All Sellers'};
    final seenIds = <String>{};

    for (final s in activeSellers) {
      final name = s.tradeName.trim().isNotEmpty
          ? s.tradeName.trim()
          : (s.companyName.trim().isNotEmpty ? s.companyName.trim() : s.contactPerson.trim());
      if (name.isEmpty) continue;
      String key = s.id.isNotEmpty ? s.id : name;
      if (seenKeys.contains(key)) {
        key = '${name}_${s.id}';
      }
      seenKeys.add(key);
      if (s.id.isNotEmpty) seenIds.add(s.id);
      final count = _countProductsForSeller(s.id, name, catalog);
      list.add(_SellerFilterOption(
        key: key,
        label: name,
        sellerId: s.id,
        productCount: count,
      ));
    }

    // Include any distinct seller assigned on catalog products not yet present
    for (final p in catalog) {
      if (p.sellerId.isNotEmpty && !seenIds.contains(p.sellerId)) {
        final resolved = _resolveSellerName(p, activeSellers);
        if (resolved != 'Unassigned' && !seenKeys.contains(p.sellerId)) {
          seenKeys.add(p.sellerId);
          seenIds.add(p.sellerId);
          final count = _countProductsForSeller(p.sellerId, resolved, catalog);
          list.add(_SellerFilterOption(
            key: p.sellerId,
            label: resolved,
            sellerId: p.sellerId,
            productCount: count,
          ));
        }
      }
    }

    // User requirement: In the All Sellers dropdown, show seller count not product count
    final totalDistinctSellers = list.length - 1;
    list[0] = _SellerFilterOption(
      key: 'All Sellers',
      label: 'All Sellers',
      productCount: totalDistinctSellers,
    );

    return list;
  }

  void _confirmPermanentDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            const SizedBox(width: 8),
            Text(
              'Permanently Delete Product?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete "${product.title}" (${product.productCode.isNotEmpty ? product.productCode : product.sku}) from the catalog?',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                'Endpoint: DELETE /api/v1/admin/products/${product.id}/permanent\n\n'
                'Warning: This action is permanent and IRREVERSIBLE. All variants, pricing, inventory mappings, and images will be permanently purged from the database.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF991B1B)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              final targetId = product.id.isNotEmpty ? product.id : product.productCode;

              // Instantly update local table and selection state (0ms)
              setState(() {
                widget.products.removeWhere(
                  (p) =>
                      (p.id.isNotEmpty && p.id == targetId) ||
                      p.productCode == targetId ||
                      p.sku == targetId,
                );
                _selectedProductCodes.remove(product.productCode);
              });

              ProductBloc? bloc;
              try {
                bloc = context.read<ProductBloc>();
              } catch (_) {}

              if (bloc != null) {
                bloc.add(
                  DeleteProductPermanently(
                    targetId,
                    onSuccess: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${product.title} permanently deleted.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: const Color(0xFF059669),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onError: (msg) {
                      setState(() {
                        if (!widget.products.contains(product)) {
                          widget.products.add(product);
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to delete: $msg',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: const Color(0xFFDC2626),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _toggleProductAvailability(Product p) {
    final newAvailable = !p.isAvailable;
    final targetId = p.id.isNotEmpty ? p.id : p.productCode;

    // Optimistically update local UI state immediately
    setState(() {
      final idx = widget.products.indexWhere(
        (item) => (p.id.isNotEmpty && item.id == p.id) || item.productCode == p.productCode,
      );
      if (idx != -1) {
        final updated = p.copyWith(isAvailable: newAvailable);
        widget.products[idx] = updated;
        widget.onProductUpdated?.call(updated);
      }
    });

    ProductBloc? bloc;
    try {
      bloc = context.read<ProductBloc>();
    } catch (_) {}

    if (bloc != null) {
      bloc.add(
        ToggleProductAvailability(
          productId: targetId,
          isAvailable: newAvailable,
          onSuccess: (updatedProduct) {
            setState(() {
              final idx = widget.products.indexWhere(
                (item) => (item.id.isNotEmpty && item.id == updatedProduct.id) || item.productCode == updatedProduct.productCode,
              );
              if (idx != -1) {
                widget.products[idx] = updatedProduct;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${p.title} availability set to ${newAvailable ? 'Available' : 'Unavailable'}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: newAvailable ? const Color(0xFF059669) : const Color(0xFF64748B),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          onError: (err) {
            // Revert optimistic update on failure
            setState(() {
              final idx = widget.products.indexWhere(
                (item) => (p.id.isNotEmpty && item.id == p.id) || item.productCode == p.productCode,
              );
              if (idx != -1) {
                widget.products[idx] = p;
                widget.onProductUpdated?.call(p);
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to update availability: $err',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    ProductBloc? productBloc;
    try {
      productBloc = context.watch<ProductBloc>();
    } catch (_) {}
    final productState = productBloc?.state ?? const ProductState();
    final isLoading = productState.status == ProductStatus.loading;
    final hasError = productState.status == ProductStatus.error;

    // Use complete catalog list across all pages when available, otherwise widget.products
    final catalog = productState.allCatalogProducts.isNotEmpty
        ? productState.allCatalogProducts
        : widget.products;

    final totalCatalogCount = productState.totalProducts > 0
        ? productState.totalProducts
        : (productState.allCatalogProducts.isNotEmpty ? productState.allCatalogProducts.length : catalog.length);

    SellerBloc? sellerBloc;
    try {
      sellerBloc = context.watch<SellerBloc>();
    } catch (_) {}

    CategoryBloc? categoryBloc;
    try {
      categoryBloc = context.watch<CategoryBloc>();
    } catch (_) {}

    final level0Categories = _resolveLevel0Categories(categoryBloc?.state);
    final categoryById = categoryBloc?.state.categoryById ?? const {};
    final categoryOptions = _buildCategoryFilterOptions(level0Categories);

    final activeSellers = _getActiveSellers(sellerBloc);
    final sellerOptions = _buildSellerOptions(activeSellers, catalog, totalCatalogCount);

    final activeSellerOption = sellerOptions.firstWhere(
      (opt) =>
          opt.key == _selectedSellerFilter ||
          (opt.sellerId != null && opt.sellerId == _selectedSellerFilter) ||
          opt.label.toLowerCase() == _selectedSellerFilter.toLowerCase(),
      orElse: () => sellerOptions.first,
    );

    // Filter products by search, category, seller, stock, and availability
    final filtered = catalog.where((p) {
      final query = _searchQuery.toLowerCase();
      final words = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

      final searchableText = '${p.title} ${p.sku} ${p.productCode} ${p.technicalName} '
          '${p.category} ${p.sellerName} ${p.vendor} ${p.hsnCode} ${p.sellerId} ${p.id} '
          '${p.assignedCollections.join(' ')} '
          '${p.variants.map((v) => '${v.label} ${v.packSize}${v.unit}').join(' ')}'
          .toLowerCase();

      final matchesSearch = words.isEmpty || words.every((word) => searchableText.contains(word));

      final matchesCategory = _matchesCategory(p, _selectedCategoryFilter, level0Categories, categoryById);

      final resolvedSeller = _resolveSellerName(p, activeSellers);
      final matchesSeller = activeSellerOption.key == 'All Sellers' ||
          (activeSellerOption.sellerId != null && p.sellerId == activeSellerOption.sellerId) ||
          p.sellerId == _selectedSellerFilter ||
          resolvedSeller.toLowerCase() == activeSellerOption.label.toLowerCase() ||
          resolvedSeller.toLowerCase() == _selectedSellerFilter.toLowerCase() ||
          p.sellerName.toLowerCase() == _selectedSellerFilter.toLowerCase() ||
          p.sellerName.toLowerCase() == activeSellerOption.label.toLowerCase() ||
          p.vendor.toLowerCase() == _selectedSellerFilter.toLowerCase() ||
          p.vendor.toLowerCase() == activeSellerOption.label.toLowerCase();

      final matchesStock = _selectedStockFilter == 'All Stock' ||
          (_selectedStockFilter == 'In Stock' && p.stock > 50) ||
          (_selectedStockFilter == 'Low Stock' && p.stock > 0 && p.stock <= 50) ||
          (_selectedStockFilter == 'Out of Stock' && p.stock == 0);

      final matchesAvailability = _selectedAvailabilityFilter == 'All Status' ||
          (_selectedAvailabilityFilter == 'Available' && p.isAvailable) ||
          (_selectedAvailabilityFilter == 'Hidden' && !p.isAvailable);

      return matchesSearch && matchesCategory && matchesSeller && matchesStock && matchesAvailability;
    }).toList();

    // Apply active column sorting
    if (_sortColumn != 'default') {
      filtered.sort((a, b) {
        int cmp = 0;
        switch (_sortColumn) {
          case 'title':
            cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
            break;
          case 'sku':
            cmp = a.productCode.toLowerCase().compareTo(b.productCode.toLowerCase());
            break;
          case 'seller':
            cmp = _resolveSellerName(a, activeSellers).toLowerCase().compareTo(_resolveSellerName(b, activeSellers).toLowerCase());
            break;
          case 'category':
            cmp = a.category.toLowerCase().compareTo(b.category.toLowerCase());
            break;
          case 'price':
            cmp = a.displayRate.compareTo(b.displayRate);
            break;
          case 'stock':
            cmp = a.stock.compareTo(b.stock);
            break;
          case 'status':
            cmp = (a.isAvailable ? 1 : 0).compareTo(b.isAvailable ? 1 : 0);
            break;
          default:
            cmp = 0;
        }
        return _sortAscending ? cmp : -cmp;
      });
    }

    final hasActiveFilters = activeSellerOption.key != 'All Sellers' ||
        _selectedCategoryFilter != 'All' ||
        _selectedStockFilter != 'All Stock' ||
        _selectedAvailabilityFilter != 'All Status' ||
        _searchQuery.isNotEmpty;

    // Server vs Client Pagination calculations
    final isServerPaginated = !hasActiveFilters &&
        productState.allCatalogProducts.isEmpty &&
        productState.pageData.totalElements > 0 &&
        (productState.pageData.totalElements > catalog.length || productState.totalPages > 1);

    final activeRowsPerPage = isServerPaginated ? productState.pageSize : _rowsPerPage;
    final totalItems = isServerPaginated ? productState.totalProducts : filtered.length;
    final totalPages = isServerPaginated
        ? productState.totalPages
        : (totalItems > 0 ? (totalItems / activeRowsPerPage).ceil() : 1);
    final safePage = isServerPaginated
        ? (productState.currentPage + 1).clamp(1, totalPages)
        : _currentPage.clamp(1, totalPages);
    final startIndex = isServerPaginated
        ? (productState.currentPage * productState.pageSize)
        : (totalItems == 0 ? 0 : (safePage - 1) * activeRowsPerPage);
    final endIndex = isServerPaginated
        ? (startIndex + filtered.length).clamp(0, totalItems)
        : (totalItems == 0 ? 0 : (startIndex + activeRowsPerPage > totalItems ? totalItems : startIndex + activeRowsPerPage));
    final paginatedProducts = isServerPaginated
        ? filtered
        : (totalItems == 0 ? <Product>[] : filtered.sublist(startIndex, endIndex));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Multi-Tenant Action & Filter Bar
        Row(
          children: [
            // Search Input Field
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by SKU, Title, Technical Name, Category, HSN or Seller...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 17,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            tooltip: 'Clear search',
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _currentPage = 1;
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF059669), width: 1.4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Seller Filter Dropdown
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: activeSellerOption.key,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  dropdownColor: surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  items: sellerOptions.map((opt) {
                    final isAll = opt.key == 'All Sellers';
                    return DropdownMenuItem<String>(
                      value: opt.key,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAll ? Icons.storefront_rounded : Icons.business_rounded,
                            size: 14,
                            color: const Color(0xFF059669),
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              opt.label,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (opt.sellerId != null && opt.sellerId!.isNotEmpty && !isAll) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: 'Seller ID: ${opt.sellerId}',
                              child: Text(
                                '(ID: ${opt.sellerId!.length > 8 ? '${opt.sellerId!.substring(0, 8)}...' : opt.sellerId})',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '${opt.productCount}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedSellerFilter = val;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Refresh Button
            // Add Product Button
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: widget.onOpenAddProduct,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  'Add Product',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),

        if (isLoading) ...[
          const SizedBox(height: 6),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(2)),
            child: LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Color(0x1A059669),
              color: Color(0xFF059669),
            ),
          ),
        ],

        if (hasError && productState.errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    productState.errorMessage!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => productBloc?.add(FetchProducts(
                    page: productState.currentPage,
                    size: productState.pageSize,
                  )),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 10),

        // Active Filter Banner (when any filter is active)
        if (hasActiveFilters) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_alt_rounded, size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Active Filters: ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                      children: [
                        if (activeSellerOption.key != 'All Sellers')
                          TextSpan(
                            text: 'Seller: ${activeSellerOption.label} • ',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        if (_selectedCategoryFilter != 'All')
                          TextSpan(
                            text: 'Category: $_selectedCategoryFilter • ',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        if (_selectedStockFilter != 'All Stock')
                          TextSpan(
                            text: 'Stock: $_selectedStockFilter • ',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        if (_selectedAvailabilityFilter != 'All Status')
                          TextSpan(
                            text: 'Status: $_selectedAvailabilityFilter • ',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        if (_searchQuery.isNotEmpty)
                          TextSpan(
                            text: 'Query: "$_searchQuery" • ',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        TextSpan(
                          text: '(${filtered.length} products found)',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _selectedSellerFilter = 'All Sellers';
                      _selectedCategoryFilter = 'All';
                      _selectedStockFilter = 'All Stock';
                      _selectedAvailabilityFilter = 'All Status';
                      _searchQuery = '';
                      _currentPage = 1;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close_rounded, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Text(
                          'Reset Filters',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Compact Filter Chips & Catalog Metrics Strip
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categoryOptions.map((cat) {
                    final isSelected = _selectedCategoryFilter == cat;
                    final catItem = level0Categories
                        .where((c) => c.name.trim().toLowerCase() == cat.trim().toLowerCase())
                        .firstOrNull;
                    final hasEmoji = catItem != null && catItem.isEmojiIcon;
                    final labelText = hasEmoji ? '${catItem.effectiveIcon} $cat' : cat;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        label: Text(labelText),
                        selected: isSelected,
                        selectedColor: isDark
                            ? const Color(0xFF059669).withValues(alpha: 0.22)
                            : const Color(0xFF059669).withValues(alpha: 0.12),
                        backgroundColor: surfaceColor,
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF059669) : borderColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                        onSelected: (_) => setState(() {
                          _selectedCategoryFilter = cat;
                          _currentPage = 1;
                        }),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // High-Density Responsive Product Table Container
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Catalog Header Title Strip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Agricultural Catalog & Master Inventory',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${filtered.length} SKUs',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ),
                          if (_sortColumn != 'default') ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => setState(() {
                                _sortColumn = 'default';
                                _sortAscending = true;
                              }),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF059669).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                      size: 11,
                                      color: const Color(0xFF059669),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sorted by ${_sortColumn.toUpperCase()} • Reset',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF059669),
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.close_rounded, size: 11, color: Color(0xFF059669)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (widget.isWide)
                      Text(
                        'Multi-Tenant Marketplace Catalog',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              Divider(height: 1, color: borderColor),

              // Bulk Actions Bar (When items are selected)
              if (_selectedProductCodes.isNotEmpty) ...[
                Container(
                  color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, size: 14, color: Color(0xFF059669)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedProductCodes.length} product${_selectedProductCodes.length > 1 ? 's' : ''} selected',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            for (final code in _selectedProductCodes) {
                              final idx = widget.products.indexWhere((p) => p.productCode == code);
                              if (idx != -1) {
                                final updated = widget.products[idx].copyWith(isAvailable: true);
                                widget.products[idx] = updated;
                                widget.onProductUpdated?.call(updated);
                              }
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${_selectedProductCodes.length} products marked as Active',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: const Color(0xFF059669),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_rounded, size: 14, color: Color(0xFF059669)),
                        label: Text(
                          'Mark Active',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF059669)),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            for (final code in _selectedProductCodes) {
                              final idx = widget.products.indexWhere((p) => p.productCode == code);
                              if (idx != -1) {
                                final updated = widget.products[idx].copyWith(isAvailable: false);
                                widget.products[idx] = updated;
                                widget.onProductUpdated?.call(updated);
                              }
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${_selectedProductCodes.length} products marked as Hidden',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: const Color(0xFF475569),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_off_rounded, size: 14, color: Color(0xFFEF4444)),
                        label: Text(
                          'Mark Hidden',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444)),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () => setState(() => _selectedProductCodes.clear()),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Clear',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),
              ],

              // Table Column Headers (For Wide/Desktop screens)
              if (widget.isWide)
                Container(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Select All Checkbox
                      SizedBox(
                        width: 24,
                        child: Checkbox(
                          value: paginatedProducts.isEmpty
                              ? false
                              : (paginatedProducts.every((p) => _selectedProductCodes.contains(p.productCode))
                                  ? true
                                  : (paginatedProducts.any((p) => _selectedProductCodes.contains(p.productCode))
                                      ? null
                                      : false)),
                          tristate: true,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          activeColor: const Color(0xFF059669),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                for (final p in paginatedProducts) {
                                  _selectedProductCodes.add(p.productCode);
                                }
                              } else {
                                for (final p in paginatedProducts) {
                                  _selectedProductCodes.remove(p.productCode);
                                }
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildSortableColHeader('title', 'PRODUCT & COMPOSITION', isDark),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildSortableColHeader('sku', 'SKU / HSN', isDark),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildSortableColHeader('seller', 'SELLER / VENDOR', isDark),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildSortableColHeader('category', 'CATEGORY & PACK', isDark),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildSortableColHeader('price', 'PRICE / MRP', isDark),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildSortableColHeader('stock', 'STOCK LEVEL', isDark),
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: _buildSortableColHeader('status', 'AVAILABILITY', isDark),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 88,
                        child: _buildColHeader('ACTIONS', isDark, alignRight: true),
                      ),
                    ],
                  ),
                ),

              if (widget.isWide) Divider(height: 1, color: borderColor),

              if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: isLoading
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Loading products from catalog...',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          )
                        : hasError
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFEF2F2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.cloud_off_rounded,
                                      size: 30,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    productState.errorMessage ?? 'Connection timed out',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Cloud backend may have been on standby.\nTap Retry now that the service is active.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => productBloc?.add(FetchProducts(
                                      page: productState.currentPage,
                                      size: productState.pageSize,
                                      isRefresh: true,
                                    )),
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: Text(
                                      'Retry Connection',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 36,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    hasActiveFilters
                                        ? 'No products matching your search criteria'
                                        : 'No products found in catalog',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paginatedProducts.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final p = paginatedProducts[index];
                    final isSelected = _selectedProductCodes.contains(p.productCode);
                    final sellerName = _resolveSellerName(p, activeSellers);
                    final sellerPhone = _resolveSellerPhoneNumber(p, activeSellers, sellerBloc);
                    final catColor = _getCategoryColor(p.category);

                    return widget.isWide
                        ? ProductTableRow(
                            key: ValueKey(p.id.isNotEmpty ? p.id : p.productCode),
                            product: p,
                            isSelected: isSelected,
                            sellerName: sellerName,
                            sellerPhoneNumber: sellerPhone,
                            categoryColor: catColor,
                            isDark: isDark,
                            borderColor: borderColor,
                            onTap: () => widget.onOpenProductDetails(p, editMode: false),
                            onToggleSelect: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedProductCodes.add(p.productCode);
                                } else {
                                  _selectedProductCodes.remove(p.productCode);
                                }
                              });
                            },
                            onSelectSeller: (name) => setState(() {
                              _selectedSellerFilter = name;
                              _currentPage = 1;
                            }),
                            onToggleStatus: () => _toggleProductAvailability(p),
                            onToggleAvailability: () => _toggleProductAvailability(p),
                            onDelete: () => _confirmPermanentDelete(context, p),
                            onView: () => widget.onOpenProductDetails(p, editMode: false),
                            onEdit: () => widget.onOpenProductDetails(p, editMode: true),
                          )
                        : ProductMobileCard(
                            product: p,
                            isSelected: isSelected,
                            sellerName: sellerName,
                            categoryColor: catColor,
                            isDark: isDark,
                            borderColor: borderColor,
                            onTap: () => widget.onOpenProductDetails(p, editMode: false),
                            onToggleSelect: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedProductCodes.add(p.productCode);
                                } else {
                                  _selectedProductCodes.remove(p.productCode);
                                }
                              });
                            },
                            onSelectSeller: (name) => setState(() {
                              _selectedSellerFilter = name;
                              _currentPage = 1;
                            }),
                            onDelete: () => _confirmPermanentDelete(context, p),
                            onView: () => widget.onOpenProductDetails(p, editMode: false),
                            onEdit: () => widget.onOpenProductDetails(p, editMode: true),
                          );
                  },
                ),

              // Enterprise Pagination Footer
              if (filtered.isNotEmpty)
                PaginationFooter(
                  totalItems: totalItems,
                  totalPages: totalPages,
                  currentPage: safePage,
                  rowsPerPage: activeRowsPerPage,
                  rowsPerPageOptions: _rowsPerPageOptions,
                  startIndex: startIndex,
                  endIndex: endIndex,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  isWide: widget.isWide,
                  onPageChanged: (newPage) {
                    if (isServerPaginated && productBloc != null) {
                      productBloc.add(FetchProducts(
                        page: newPage - 1,
                        size: activeRowsPerPage,
                      ));
                    } else {
                      setState(() => _currentPage = newPage);
                    }
                  },
                  onRowsPerPageChanged: (newRows) {
                    setState(() {
                      _rowsPerPage = newRows;
                      _currentPage = 1;
                    });
                    if (isServerPaginated && productBloc != null) {
                      productBloc.add(FetchProducts(
                        page: 0,
                        size: newRows,
                      ));
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Sortable Column Header Widget with indicator
  Widget _buildSortableColHeader(
    String colKey,
    String title,
    bool isDark, {
    bool alignRight = false,
  }) {
    final isSorted = _sortColumn == colKey;
    final tooltipMsg = isSorted
        ? (_sortAscending ? 'Sorted Ascending (Click for Descending)' : 'Sorted Descending (Click to reset to original order)')
        : 'Click to sort';

    return Tooltip(
      message: tooltipMsg,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: () {
          setState(() {
            if (_sortColumn == colKey) {
              if (_sortAscending) {
                _sortAscending = false;
              } else {
                // 3rd click: Reset to default original order
                _sortColumn = 'default';
                _sortAscending = true;
              }
            } else {
              _sortColumn = colKey;
              _sortAscending = true;
            }
          });
        },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: isSorted ? FontWeight.w900 : FontWeight.w800,
                  letterSpacing: 0.6,
                  color: isSorted
                      ? const Color(0xFF059669)
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              isSorted
                  ? (_sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 11,
              color: isSorted
                  ? const Color(0xFF059669)
                  : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    ),
  );
}

  // Column Header Widget with alignment
  Widget _buildColHeader(String title, bool isDark, {bool alignRight = false}) {
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }


}
