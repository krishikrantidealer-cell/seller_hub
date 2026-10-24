import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/collection.dart';
import '../../../core/models/product.dart';
import '../../../logic/collection/collection_bloc.dart';
import '../../../logic/collection/collection_event.dart';
import '../../../logic/collection/collection_state.dart';
import '../../../logic/product/product_bloc.dart';
import '../../../logic/product/product_event.dart';
import '../../../logic/product/product_state.dart';

class AssignCollectionsDialog extends StatefulWidget {
  final Product product;
  final void Function(Product updatedProduct)? onProductUpdated;

  const AssignCollectionsDialog({
    super.key,
    required this.product,
    this.onProductUpdated,
  });

  @override
  State<AssignCollectionsDialog> createState() => _AssignCollectionsDialogState();
}

class _AssignCollectionsDialogState extends State<AssignCollectionsDialog> {
  final Set<String> _selectedCollectionIds = {};
  final Set<String> _selectedSubCollectionIds = {};

  @override
  void initState() {
    super.initState();
    // Ensure collections are fetched
    final colState = context.read<CollectionBloc>().state;
    if (colState.collections.isEmpty) {
      context.read<CollectionBloc>().add(const FetchCollections());
    }

    // Populate initial selections from product's assignedCollections or collectionIds
    final initialAssigned = widget.product.assignedCollections.isNotEmpty
        ? widget.product.assignedCollections
        : [...widget.product.collectionIds, ...widget.product.subCollectionIds];

    final allKnownRootIds = colState.collections.map((c) => c.id).toSet();
    final allKnownSubIds = <String>{};
    for (final c in colState.collections) {
      for (final s in c.subCollections) {
        allKnownSubIds.add(s.id);
      }
    }

    for (final id in initialAssigned) {
      if (allKnownRootIds.contains(id)) {
        _selectedCollectionIds.add(id);
      } else if (allKnownSubIds.contains(id)) {
        _selectedSubCollectionIds.add(id);
      } else {
        if (widget.product.collectionIds.contains(id)) {
          _selectedCollectionIds.add(id);
        } else {
          _selectedSubCollectionIds.add(id);
        }
      }
    }
  }

  void _toggleCollection(CollectionItem collection, bool? isChecked) {
    setState(() {
      if (isChecked == true) {
        _selectedCollectionIds.add(collection.id);
      } else {
        _selectedCollectionIds.remove(collection.id);
      }
    });
  }

  void _toggleSubCollection(String collectionId, String subCollectionId, bool? isChecked) {
    setState(() {
      if (isChecked == true) {
        _selectedSubCollectionIds.add(subCollectionId);
      } else {
        _selectedSubCollectionIds.remove(subCollectionId);
      }
    });
  }

  void _handleSave() {
    // Separate selected root collection IDs and subCollection IDs based on live taxonomy
    final colState = context.read<CollectionBloc>().state;
    final allKnownRootIds = colState.collections.map((c) => c.id).toSet();
    final allKnownSubIds = <String>{};
    for (final c in colState.collections) {
      for (final s in c.subCollections) {
        allKnownSubIds.add(s.id);
      }
    }

    final finalRootIds = _selectedCollectionIds.where((id) => allKnownRootIds.contains(id)).toList();
    final finalSubIds = _selectedSubCollectionIds.where((id) => allKnownSubIds.contains(id)).toList();

    context.read<ProductBloc>().add(
          AssignProductCollections(
            productId: widget.product.id,
            collectionIds: finalRootIds,
            subCollectionIds: finalSubIds,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final cardBgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);

    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (previous, current) =>
          previous.lastAssignedProduct != current.lastAssignedProduct &&
          current.lastAssignedProduct != null,
      listener: (context, state) {
        final updated = state.lastAssignedProduct!;
        widget.onProductUpdated?.call(updated);
        context.read<CollectionBloc>().add(const FetchCollections(isRefresh: true));
        Navigator.of(context).pop(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Storefront collections updated for "${widget.product.title}".',
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
      },
      child: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, prodState) {
          final isAssigning = prodState.isAssigningCollections;
          final errorMsg = prodState.assignCollectionsError;

          return Dialog(
            backgroundColor: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680, maxHeight: 800),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pinned Header
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
                            Icons.collections_bookmark_rounded,
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
                                'Assign Storefront Collections',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.product.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF059669),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'POST {{baseUrl}}/api/v1/admin/products/${widget.product.id}/collections',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: isAssigning ? null : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: borderColor),

                  // Selection Summary Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    color: cardBgColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_selectedCollectionIds.length} Collections',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_selectedSubCollectionIds.length} Sub-Nodes',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7C3AED),
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: isAssigning
                              ? null
                              : () {
                                  setState(() {
                                    _selectedCollectionIds.clear();
                                    _selectedSubCollectionIds.clear();
                                  });
                                },
                          child: Text(
                            'Clear All',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: borderColor),

                  // Error notification if present
                  if (errorMsg != null)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              errorMsg,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Scrollable Collections Taxonomy Tree
                  Flexible(
                    child: BlocBuilder<CollectionBloc, CollectionState>(
                      builder: (context, colState) {
                        if (colState.status == CollectionStatus.loading && colState.collections.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (colState.collections.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(
                                'No collections found. Create a collection first.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: colState.collections.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final collection = colState.collections[index];
                            final isCollectionSelected = _selectedCollectionIds.contains(collection.id);

                            return Container(
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCollectionSelected ? const Color(0xFF059669) : borderColor,
                                  width: isCollectionSelected ? 1.5 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Collection Header Tile
                                  Material(
                                    color: Colors.transparent,
                                    child: CheckboxListTile(
                                      value: isCollectionSelected,
                                      activeColor: const Color(0xFF059669),
                                      onChanged: isAssigning ? null : (val) => _toggleCollection(collection, val),
                                      title: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              collection.name,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '/${collection.slug}',
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 11,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: collection.description.isNotEmpty
                                          ? Text(
                                              collection.description,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          : null,
                                    ),
                                  ),

                                  // Child Sub-Collections Matrix
                                  if (collection.subCollections.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                      color: cardBgColor,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: collection.subCollections.map((sub) {
                                              final isSubSelected = _selectedSubCollectionIds.contains(sub.id);
                                              return FilterChip(
                                                selected: isSubSelected,
                                                showCheckmark: true,
                                                checkmarkColor: Colors.white,
                                                selectedColor: const Color(0xFF7C3AED),
                                                backgroundColor: surfaceColor,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                  side: BorderSide(
                                                    color: isSubSelected
                                                        ? const Color(0xFF7C3AED)
                                                        : borderColor,
                                                  ),
                                                ),
                                                label: Text(
                                                  sub.name,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: isSubSelected ? FontWeight.w700 : FontWeight.w600,
                                                    color: isSubSelected
                                                        ? Colors.white
                                                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                                  ),
                                                ),
                                                onSelected: isAssigning
                                                    ? null
                                                    : (val) => _toggleSubCollection(collection.id, sub.id, val),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  Divider(height: 1, color: borderColor),

                  // Pinned Footer with Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: isAssigning ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: isAssigning ? null : _handleSave,
                          icon: isAssigning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            isAssigning ? 'Saving Collections...' : 'Save Collections Assignment',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      ),
    );
  }
}
