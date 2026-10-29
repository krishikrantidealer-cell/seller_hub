import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/collection.dart';
import '../../../core/models/product.dart';
import '../../../logic/collection/collection_bloc.dart';
import '../../../logic/collection/collection_event.dart';
import '../../../logic/product/product_bloc.dart';
import '../../../logic/product/product_event.dart';
import '../../../logic/product/product_state.dart';
import '../widgets/app_product_image.dart';

/// Full-screen view for managing product assignments to a collection
/// and its child sub-collections with rich multi-criteria filters.
class AssignProductsView extends StatefulWidget {
  final CollectionItem collection;

  const AssignProductsView({
    super.key,
    required this.collection,
  });

  @override
  State<AssignProductsView> createState() => _AssignProductsViewState();
}

class _AssignProductsViewState extends State<AssignProductsView> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedProductIds = {};
  String? _selectedSubCollectionId;
  bool _includeRootCollection = true;
  String _searchQuery = '';
  bool _isSaving = false;

  // Filters
  String _selectedCategoryFilter = 'All';
  String _selectedSellerFilter = 'All Sellers';
  String _selectedAssignmentFilter = 'All';
  String _selectedStockFilter = 'All Stock';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    // Populate initial selections from products currently assigned to this collection
    final products = context.read<ProductBloc>().state.products;
    final allCollectionIds = {
      widget.collection.id,
      ...widget.collection.subCollections.map((s) => s.id),
    };

    for (final p in products) {
      if (p.assignedCollections.any((id) => allCollectionIds.contains(id))) {
        _selectedProductIds.add(p.id);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _toggleProduct(String productId, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        _selectedProductIds.add(productId);
      } else {
        _selectedProductIds.remove(productId);
      }
    });
  }

  void _selectAll(List<Product> visibleProducts) {
    setState(() {
      for (final p in visibleProducts) {
        _selectedProductIds.add(p.id);
      }
    });
  }

  void _deselectAll(List<Product> visibleProducts) {
    setState(() {
      for (final p in visibleProducts) {
        _selectedProductIds.remove(p.id);
      }
    });
  }

  void _resetAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategoryFilter = 'All';
      _selectedSellerFilter = 'All Sellers';
      _selectedAssignmentFilter = 'All';
      _selectedStockFilter = 'All Stock';
    });
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    final productBloc = context.read<ProductBloc>();
    final allProducts = productBloc.state.products;
    final collectionSubIds = widget.collection.subCollections.map((s) => s.id).toSet();
    int modifiedCount = 0;

    for (final product in allProducts) {
      final wasAssigned = product.assignedCollections.contains(widget.collection.id) ||
          product.assignedCollections.any((id) => collectionSubIds.contains(id));
      final isNowSelected = _selectedProductIds.contains(product.id);

      if (wasAssigned != isNowSelected ||
          (_selectedSubCollectionId != null && isNowSelected && !product.assignedCollections.contains(_selectedSubCollectionId))) {
        modifiedCount++;

        // Calculate updated collectionIds and subCollectionIds for this product
        final currentCollections = List<String>.from(product.assignedCollections);

        if (isNowSelected) {
          // If sub-collection chosen and includeRoot is false, map to sub-collection only
          if (_selectedSubCollectionId == null || _includeRootCollection) {
            if (!currentCollections.contains(widget.collection.id)) {
              currentCollections.add(widget.collection.id);
            }
          } else {
            currentCollections.remove(widget.collection.id);
          }

          if (_selectedSubCollectionId != null && !currentCollections.contains(_selectedSubCollectionId)) {
            currentCollections.add(_selectedSubCollectionId!);
          }
        } else {
          // Remove root and its subcollections
          currentCollections.remove(widget.collection.id);
          currentCollections.removeWhere((id) => collectionSubIds.contains(id));
        }

        // Separate root vs sub collection ids using all known collections in state
        final colState = context.read<CollectionBloc>().state;
        final allKnownRootIds = {
          widget.collection.id,
          ...colState.collections.map((c) => c.id),
        };
        final allKnownSubIds = {
          ...widget.collection.subCollections.map((s) => s.id),
          for (final c in colState.collections)
            for (final s in c.subCollections) s.id,
        };

        final rootIds = currentCollections.where((id) => allKnownRootIds.contains(id)).toList();
        final subIds = currentCollections.where((id) => allKnownSubIds.contains(id)).toList();

        productBloc.add(
          AssignProductCollections(
            productId: product.id,
            collectionIds: rootIds,
            subCollectionIds: subIds,
          ),
        );
      }
    }

    if (mounted) {
      context.read<CollectionBloc>().add(const FetchCollections(isRefresh: true));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            modifiedCount > 0
                ? 'Updated collection assignments for $modifiedCount product(s).'
                : 'No changes made to product collection assignments.',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, prodState) {
        final allProducts = prodState.allCatalogProducts.isNotEmpty
            ? prodState.allCatalogProducts
            : prodState.products;

        // Dynamic categories from catalog
        final categories = <String>{'All'};
        for (final p in allProducts) {
          if (p.category.trim().isNotEmpty) categories.add(p.category.trim());
        }
        final sortedCategories = categories.toList()..sort();

        // Dynamic sellers from catalog
        final sellers = <String>{'All Sellers'};
        for (final p in allProducts) {
          final s = p.sellerName.trim().isNotEmpty
              ? p.sellerName.trim()
              : (p.vendor.trim().isNotEmpty ? p.vendor.trim() : (p.sellerId.isNotEmpty ? p.sellerId : 'Krishi Kranti Organics'));
          sellers.add(s);
        }
        final sortedSellers = sellers.toList()..sort();

        final allCollectionIds = {
          widget.collection.id,
          ...widget.collection.subCollections.map((s) => s.id),
        };

        // Filter products
        final filteredProducts = allProducts.where((p) {
          // 1. Search Query
          if (_searchQuery.isNotEmpty) {
            final words = _searchQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
            final searchable = '${p.title} ${p.sku} ${p.productCode} ${p.technicalName} '
                '${p.category} ${p.sellerName} ${p.vendor} ${p.sellerId}'.toLowerCase();
            final matches = words.every((word) => searchable.contains(word));
            if (!matches) return false;
          }

          // 2. Category Filter
          if (_selectedCategoryFilter != 'All' && p.category.toLowerCase() != _selectedCategoryFilter.toLowerCase()) {
            return false;
          }

          // 3. Seller Filter
          if (_selectedSellerFilter != 'All Sellers') {
            final vendorName = p.sellerName.trim().isNotEmpty
                ? p.sellerName.trim()
                : (p.vendor.trim().isNotEmpty ? p.vendor.trim() : (p.sellerId.isNotEmpty ? p.sellerId : 'Krishi Kranti Organics'));
            if (vendorName != _selectedSellerFilter) return false;
          }

          // 4. Assignment Filter
          final isAssigned = p.assignedCollections.any((id) => allCollectionIds.contains(id)) || _selectedProductIds.contains(p.id);
          if (_selectedAssignmentFilter == 'Assigned' && !isAssigned) {
            return false;
          } else if (_selectedAssignmentFilter == 'Unassigned' && isAssigned) {
            return false;
          }

          // 5. Stock Filter
          if (_selectedStockFilter == 'In Stock' && p.stock <= 50) {
            return false;
          } else if (_selectedStockFilter == 'Low Stock' && (p.stock <= 0 || p.stock > 50)) {
            return false;
          } else if (_selectedStockFilter == 'Out of Stock' && p.stock > 0) {
            return false;
          }

          return true;
        }).toList();

        final assignedCount = allProducts.where((p) =>
            p.assignedCollections.any((id) => allCollectionIds.contains(id)) ||
            _selectedProductIds.contains(p.id)).length;
        final unassignedCount = allProducts.length - assignedCount;

        final hasActiveFilters = _searchQuery.isNotEmpty ||
            _selectedCategoryFilter != 'All' ||
            _selectedSellerFilter != 'All Sellers' ||
            _selectedAssignmentFilter != 'All' ||
            _selectedStockFilter != 'All Stock';

        return Scaffold(
          backgroundColor: bgColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(68),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              child: SafeArea(
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Back to Collections',
                      color: textSecondary,
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),

                    // Icon
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.playlist_add_check_rounded,
                        color: Color(0xFF059669),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title & Collection details
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign Products to Collection',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                widget.collection.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '/${widget.collection.slug}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10.5,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                              if (widget.collection.subCollections.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${widget.collection.subCollections.length} sub-collections',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF7C3AED),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Selected count pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
                          const SizedBox(width: 6),
                          Text(
                            '${_selectedProductIds.length} Selected',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Primary Save Button
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 16),
                      label: Text(
                        _isSaving ? 'Assigning...' : 'Save Product Assignments',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Target Sub-Collection Selector Strip (if collection has sub-collections)
              if (widget.collection.subCollections.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.account_tree_outlined, size: 16, color: Color(0xFF7C3AED)),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Target Assignment:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: Text('${widget.collection.name} (Root Only)'),
                                    labelStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedSubCollectionId == null ? Colors.white : textPrimary,
                                    ),
                                    selected: _selectedSubCollectionId == null,
                                    selectedColor: const Color(0xFF059669),
                                    onSelected: (val) {
                                      if (val) setState(() => _selectedSubCollectionId = null);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ...widget.collection.subCollections.map((sub) {
                                    final isSub = _selectedSubCollectionId == sub.id;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        avatar: isSub
                                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                                            : null,
                                        label: Text('${sub.name} (${sub.productCount})'),
                                        labelStyle: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: isSub ? Colors.white : textPrimary,
                                        ),
                                        selected: isSub,
                                        selectedColor: const Color(0xFF7C3AED),
                                        onSelected: (val) {
                                          setState(() {
                                            _selectedSubCollectionId = val ? sub.id : null;
                                          });
                                        },
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedSubCollectionId != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: Checkbox(
                                  value: _includeRootCollection,
                                  activeColor: const Color(0xFF059669),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) => setState(() => _includeRootCollection = val ?? true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Also assign to root collection ',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '(${widget.collection.name})',
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                                      ),
                                      TextSpan(
                                        text: _includeRootCollection
                                            ? ' — Products will appear in both "${widget.collection.subCollections.firstWhere((s) => s.id == _selectedSubCollectionId, orElse: () => widget.collection.subCollections.first).name}" and "${widget.collection.name}"'
                                            : ' — Products will ONLY appear in "${widget.collection.subCollections.firstWhere((s) => s.id == _selectedSubCollectionId, orElse: () => widget.collection.subCollections.first).name}"',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Filter & Search Toolbar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Column(
                  children: [
                    // Search Bar & Dropdowns
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // 1. Search Field
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: 260,
                                maxWidth: constraints.maxWidth > 900 ? 380 : constraints.maxWidth,
                              ),
                              child: SizedBox(
                                height: 40,
                                child: TextField(
                                  controller: _searchController,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search SKU, title, vendor, or category...',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: textSecondary,
                                    ),
                                    prefixIcon: Icon(Icons.search_rounded, size: 17, color: textSecondary),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.close_rounded, size: 16),
                                            tooltip: 'Clear search',
                                            color: textSecondary,
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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

                            // 2. Category Filter Dropdown
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: sortedCategories.contains(_selectedCategoryFilter) ? _selectedCategoryFilter : 'All',
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                  dropdownColor: surfaceColor,
                                  borderRadius: BorderRadius.circular(8),
                                  items: sortedCategories.map((cat) {
                                    return DropdownMenuItem<String>(
                                      value: cat,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            cat == 'All' ? Icons.category_outlined : Icons.label_rounded,
                                            size: 14,
                                            color: const Color(0xFF059669),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(cat == 'All' ? 'All Categories' : cat),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCategoryFilter = val);
                                  },
                                ),
                              ),
                            ),

                            // 3. Seller Filter Dropdown
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: sortedSellers.contains(_selectedSellerFilter) ? _selectedSellerFilter : 'All Sellers',
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                  dropdownColor: surfaceColor,
                                  borderRadius: BorderRadius.circular(8),
                                  items: sortedSellers.map((s) {
                                    return DropdownMenuItem<String>(
                                      value: s,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            s == 'All Sellers' ? Icons.storefront_rounded : Icons.business_rounded,
                                            size: 14,
                                            color: const Color(0xFF2563EB),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(s.length > 22 ? '${s.substring(0, 20)}...' : s),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedSellerFilter = val);
                                  },
                                ),
                              ),
                            ),

                            // 4. Assignment Filter Dropdown
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedAssignmentFilter,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                  dropdownColor: surfaceColor,
                                  borderRadius: BorderRadius.circular(8),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'All',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 6),
                                          Text('All Products (${allProducts.length})'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Assigned',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF059669)),
                                          const SizedBox(width: 6),
                                          Text('Assigned ($assignedCount)'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Unassigned',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.radio_button_unchecked, size: 14, color: Color(0xFFD97706)),
                                          const SizedBox(width: 6),
                                          Text('Unassigned ($unassignedCount)'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedAssignmentFilter = val);
                                  },
                                ),
                              ),
                            ),

                            // 5. Stock Filter Dropdown
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedStockFilter,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                  dropdownColor: surfaceColor,
                                  borderRadius: BorderRadius.circular(8),
                                  items: const [
                                    DropdownMenuItem(value: 'All Stock', child: Text('All Stock')),
                                    DropdownMenuItem(value: 'In Stock', child: Text('In Stock (>50)')),
                                    DropdownMenuItem(value: 'Low Stock', child: Text('Low Stock (1-50)')),
                                    DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock (0)')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedStockFilter = val);
                                  },
                                ),
                              ),
                            ),

                            // Reset Filters Button
                            if (hasActiveFilters)
                              TextButton.icon(
                                onPressed: _resetAllFilters,
                                icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFFEF4444)),
                                label: Text(
                                  'Reset Filters',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Quick Selection Actions & Showing Count
                    Row(
                      children: [
                        Text(
                          'Showing ${filteredProducts.length} of ${allProducts.length} products',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _selectAll(filteredProducts),
                          icon: const Icon(Icons.done_all_rounded, size: 15, color: Color(0xFF2563EB)),
                          label: Text(
                            'Select All Filtered (${filteredProducts.length})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _deselectAll(filteredProducts),
                          icon: const Icon(Icons.remove_done_rounded, size: 15, color: Color(0xFFEF4444)),
                          label: Text(
                            'Deselect All',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Product Catalog List
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.search_off_rounded, size: 40, color: textSecondary),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products match your current filters.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try clearing your search query or selecting a different category/seller filter.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                            if (hasActiveFilters) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _resetAllFilters,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Reset All Filters'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        itemCount: filteredProducts.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final isSelected = _selectedProductIds.contains(product.id);
                          final isOriginallyAssigned = product.assignedCollections.any((id) => allCollectionIds.contains(id));
                          final catColor = _getCategoryColor(product.category);

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _isSaving ? null : () => _toggleProduct(product.id, !isSelected),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF059669).withValues(alpha: isDark ? 0.12 : 0.06)
                                      : surfaceColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF059669) : borderColor,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Checkbox
                                    Checkbox(
                                      value: isSelected,
                                      activeColor: const Color(0xFF059669),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: _isSaving ? null : (val) => _toggleProduct(product.id, val),
                                    ),
                                    const SizedBox(width: 8),

                                    // Thumbnail
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: AppProductImage(
                                          imageUrl: product.image,
                                          width: 50,
                                          height: 50,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Details (Title, SKU, Vendor, Category)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  product.title,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),

                                              // Assigned status badge
                                              if (isOriginallyAssigned)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF059669)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Assigned',
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.w700,
                                                          color: const Color(0xFF059669),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              // SKU
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'SKU: ${product.sku}',
                                                  style: GoogleFonts.jetBrainsMono(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: textSecondary,
                                                  ),
                                                ),
                                              ),

                                              // Category Pill
                                              if (product.category.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: catColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    product.category,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: catColor,
                                                    ),
                                                  ),
                                                ),

                                              // Vendor / Seller
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.storefront_rounded, size: 12, color: Color(0xFF2563EB)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    product.sellerName.isNotEmpty
                                                        ? product.sellerName
                                                        : (product.vendor.isNotEmpty ? product.vendor : 'Krishi Kranti Organics'),
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF2563EB),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Price & Stock
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${(product.displayRate > 0 ? product.displayRate : product.price).toStringAsFixed(0)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF059669),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: product.stock > 50
                                                ? const Color(0xFF059669).withValues(alpha: 0.1)
                                                : (product.stock > 0
                                                    ? const Color(0xFFD97706).withValues(alpha: 0.1)
                                                    : const Color(0xFFEF4444).withValues(alpha: 0.1)),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            product.stock > 50
                                                ? 'Stock: ${product.stock}'
                                                : (product.stock > 0 ? 'Low: ${product.stock}' : 'Out of Stock'),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: product.stock > 50
                                                  ? const Color(0xFF059669)
                                                  : (product.stock > 0 ? const Color(0xFFD97706) : const Color(0xFFEF4444)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Backwards compatibility alias for existing callers
typedef AssignProductsToCollectionDialog = AssignProductsView;
