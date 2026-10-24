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
import 'app_product_image.dart';

class AssignProductsToCollectionDialog extends StatefulWidget {
  final CollectionItem collection;

  const AssignProductsToCollectionDialog({
    super.key,
    required this.collection,
  });

  @override
  State<AssignProductsToCollectionDialog> createState() => _AssignProductsToCollectionDialogState();
}

class _AssignProductsToCollectionDialogState extends State<AssignProductsToCollectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedProductIds = {};
  String? _selectedSubCollectionId;
  bool _includeRootCollection = true;
  String _searchQuery = '';
  bool _isSaving = false;

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
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final cardBgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, prodState) {
        final allProducts = prodState.products;
        final filteredProducts = allProducts.where((p) {
          if (_searchQuery.isEmpty) return true;
          final matchTitle = p.title.toLowerCase().contains(_searchQuery);
          final matchSku = p.sku.toLowerCase().contains(_searchQuery);
          final matchVendor = p.vendor.toLowerCase().contains(_searchQuery);
          return matchTitle || matchSku || matchVendor;
        }).toList();

        return Dialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
              maxHeight: 780,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Pinned Dialog Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assign Products to Collection',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 2,
                              children: [
                                Text(
                                  widget.collection.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '/${widget.collection.slug}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'API: POST {{baseUrl}}/api/v1/admin/products/{productId}/collections',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: borderColor),

                // 2. Sub-Collection Mapping Selector (if available)
                if (widget.collection.subCollections.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    color: cardBgColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_tree_outlined, size: 16, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 8),
                            Text(
                              'Map to Sub-Collection:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Direct Only (None)'),
                                      selected: _selectedSubCollectionId == null,
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
                                          label: Text(sub.name),
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
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _includeRootCollection,
                                  activeColor: const Color(0xFF059669),
                                  onChanged: (val) => setState(() => _includeRootCollection = val ?? true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Also assign to parent collection (${widget.collection.name})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                // 3. Search and Quick Selection Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            hintText: 'Search products by title, SKU, or vendor...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
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
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_selectedProductIds.length} Selected',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _selectAll(filteredProducts),
                        child: Text(
                          'Select All',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _deselectAll(filteredProducts),
                        child: Text(
                          'Clear',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: borderColor),

                // 4. Products Selection List
                Flexible(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              'No products found matching "$_searchQuery".',
                              style: GoogleFonts.plusJakartaSans(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          itemCount: filteredProducts.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final isSelected = _selectedProductIds.contains(product.id);

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: _isSaving ? null : () => _toggleProduct(product.id, !isSelected),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF059669).withValues(alpha: 0.06)
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF059669) : borderColor,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        activeColor: const Color(0xFF059669),
                                        onChanged: _isSaving ? null : (val) => _toggleProduct(product.id, val),
                                      ),
                                      const SizedBox(width: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: SizedBox(
                                          width: 44,
                                          height: 44,
                                          child: AppProductImage(
                                            imageUrl: product.image,
                                            width: 44,
                                            height: 44,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.title,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(
                                                  'SKU: ${product.sku}',
                                                  style: GoogleFonts.jetBrainsMono(
                                                    fontSize: 11,
                                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Flexible(
                                                  child: Text(
                                                    product.vendor,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 11.5,
                                                      color: const Color(0xFF2563EB),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${product.price.toStringAsFixed(0)}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF059669),
                                            ),
                                          ),
                                          Text(
                                            'Stock: ${product.stock}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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

                Divider(height: 1, color: borderColor),

                // 5. Pinned Footer Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                            : const Icon(Icons.check_rounded, size: 16),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
