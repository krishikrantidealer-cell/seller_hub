import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/core/models/seller.dart';
import 'package:seller_hub/presentation/dashboard/widgets/pagination_footer.dart';
import 'package:seller_hub/presentation/dashboard/widgets/product_mobile_card.dart';
import 'package:seller_hub/presentation/dashboard/widgets/product_table_row.dart';

class ProductCatalogView extends StatefulWidget {
  final List<Product> products;
  final List<SellerProfile> sellers;
  final String initialSellerFilter;
  final bool isWide;
  final void Function(Product product, {bool editMode}) onOpenProductDetails;
  final VoidCallback onOpenAddProduct;
  final ValueChanged<Product>? onProductUpdated;

  const ProductCatalogView({
    super.key,
    required this.products,
    required this.sellers,
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
  int _rowsPerPage = 10;
  final List<int> _rowsPerPageOptions = const [5, 10, 20, 50];

  final List<String> _categoryFilterOptions = const [
    'All',
    'Insecticides',
    'Seeds',
    'Fertilizers',
    'Fungicides',
    'Bio Stimulants',
    'Herbicides',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSellerFilter = widget.initialSellerFilter;
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

  String _resolveSellerName(Product p) {
    if (p.vendor.isNotEmpty && p.vendor != 'TEST DATA - temporary placeholder') {
      return p.vendor;
    }
    for (final s in widget.sellers) {
      if (s.id == p.sellerId || s.sellerCode == p.sellerId) {
        return s.tradeName;
      }
    }
    return 'Krishi Kranti Organics';
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

  List<String> get _sellerFilterOptions {
    final sellers = <String>{'All Sellers'};
    for (final p in widget.products) {
      final name = _resolveSellerName(p);
      sellers.add(name);
    }
    for (final s in widget.sellers) {
      sellers.add(s.tradeName);
    }
    return sellers.toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    // Filter products by search, category, seller, stock, and availability
    final filtered = widget.products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.productCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.technicalName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.hsnCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.vendor.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sellerId.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategoryFilter == 'All' ||
          p.category.toLowerCase() == _selectedCategoryFilter.toLowerCase();

      final resolvedSeller = _resolveSellerName(p);
      final matchesSeller = _selectedSellerFilter == 'All Sellers' ||
          resolvedSeller == _selectedSellerFilter ||
          p.vendor == _selectedSellerFilter ||
          p.sellerId == _selectedSellerFilter;

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
            cmp = _resolveSellerName(a).toLowerCase().compareTo(_resolveSellerName(b).toLowerCase());
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

    // Pagination calculations
    final totalItems = filtered.length;
    final totalPages = totalItems > 0 ? (totalItems / _rowsPerPage).ceil() : 1;
    final safePage = _currentPage.clamp(1, totalPages);
    final startIndex = totalItems == 0 ? 0 : (safePage - 1) * _rowsPerPage;
    final endIndex = totalItems == 0 ? 0 : (startIndex + _rowsPerPage > totalItems ? totalItems : startIndex + _rowsPerPage);
    final paginatedProducts = totalItems == 0 ? <Product>[] : filtered.sublist(startIndex, endIndex);

    final inStockCount = widget.products.where((p) => p.stock > 50).length;
    final lowStockCount = widget.products.where((p) => p.stock > 0 && p.stock <= 50).length;
    final sellersCount = _sellerFilterOptions.where((s) => s != 'All Sellers').length;

    final hasActiveFilters = _selectedSellerFilter != 'All Sellers' ||
        _selectedCategoryFilter != 'All' ||
        _selectedStockFilter != 'All Stock' ||
        _selectedAvailabilityFilter != 'All Status' ||
        _searchQuery.isNotEmpty;

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
                  onChanged: (val) => setState(() {
                    _searchQuery = val.trim();
                    _currentPage = 1;
                  }),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by SKU, Title, Technical Name, HSN or Seller...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
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
                  value: _sellerFilterOptions.contains(_selectedSellerFilter) ? _selectedSellerFilter : 'All Sellers',
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  dropdownColor: surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  items: _sellerFilterOptions.map((s) {
                    return DropdownMenuItem<String>(
                      value: s,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            s == 'All Sellers' ? Icons.storefront_rounded : Icons.business_rounded,
                            size: 14,
                            color: const Color(0xFF059669),
                          ),
                          const SizedBox(width: 6),
                          Text(s.length > 20 ? '${s.substring(0, 18)}...' : s),
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
                        if (_selectedSellerFilter != 'All Sellers')
                          TextSpan(
                            text: 'Seller: $_selectedSellerFilter • ',
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
                  onTap: () => setState(() {
                    _selectedSellerFilter = 'All Sellers';
                    _selectedCategoryFilter = 'All';
                    _selectedStockFilter = 'All Stock';
                    _selectedAvailabilityFilter = 'All Status';
                    _searchQuery = '';
                    _currentPage = 1;
                  }),
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
                  children: _categoryFilterOptions.map((cat) {
                    final isSelected = _selectedCategoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        label: Text(cat),
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
            if (widget.isWide) ...[
              const SizedBox(width: 8),
              _buildMiniMetricBadge('Total', '${filtered.length}', const Color(0xFF059669), isDark),
              const SizedBox(width: 6),
              _buildMiniMetricBadge('In Stock', '$inStockCount', const Color(0xFF10B981), isDark),
              const SizedBox(width: 6),
              _buildMiniMetricBadge('Low Stock', '$lowStockCount', const Color(0xFFEF4444), isDark),
              const SizedBox(width: 6),
              _buildMiniMetricBadge('Sellers', '$sellersCount', const Color(0xFF3B82F6), isDark),
            ],
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
                        width: 88,
                        child: _buildSortableColHeader('status', 'STATUS', isDark),
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
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 36,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No products matching your search criteria',
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
                    final sellerName = _resolveSellerName(p);
                    final catColor = _getCategoryColor(p.category);

                    return widget.isWide
                        ? ProductTableRow(
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
                            onToggleStatus: () {
                              setState(() {
                                final idx = widget.products.indexWhere((item) => item.productCode == p.productCode);
                                if (idx != -1) {
                                  final updated = p.copyWith(isAvailable: !p.isAvailable);
                                  widget.products[idx] = updated;
                                  widget.onProductUpdated?.call(updated);
                                }
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${p.title} marked as ${!p.isAvailable ? 'Active' : 'Hidden'}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: !p.isAvailable ? const Color(0xFF059669) : const Color(0xFF64748B),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
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
                  rowsPerPage: _rowsPerPage,
                  rowsPerPageOptions: _rowsPerPageOptions,
                  startIndex: startIndex,
                  endIndex: endIndex,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  isWide: widget.isWide,
                  onPageChanged: (newPage) => setState(() => _currentPage = newPage),
                  onRowsPerPageChanged: (newRows) => setState(() {
                    _rowsPerPage = newRows;
                    _currentPage = 1;
                  }),
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


  Widget _buildMiniMetricBadge(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
