import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/collection.dart';
import '../../../logic/collection/collection_bloc.dart';
import '../../../logic/collection/collection_event.dart';
import '../../../logic/collection/collection_state.dart';
import '../widgets/app_product_image.dart';
import '../widgets/create_collection_dialog.dart';
import '../widgets/edit_collection_dialog.dart';
import '../widgets/assign_products_to_collection_dialog.dart';
import '../../../logic/product/product_bloc.dart';
import '../../../logic/product/product_state.dart';

class CollectionsView extends StatefulWidget {
  final bool isWide;

  const CollectionsView({
    super.key,
    required this.isWide,
  });

  @override
  State<CollectionsView> createState() => _CollectionsViewState();
}

class _CollectionsViewState extends State<CollectionsView> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedCollectionIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleExpanded(String id) {
    setState(() {
      if (_expandedCollectionIds.contains(id)) {
        _expandedCollectionIds.remove(id);
      } else {
        _expandedCollectionIds.add(id);
      }
    });
  }

  void _openCreateCollectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const CreateCollectionDialog(),
    );
  }

  void _openEditCollectionDialog(BuildContext context, CollectionItem item) {
    showDialog(
      context: context,
      builder: (ctx) => EditCollectionDialog(collection: item),
    );
  }

  void _openAssignProductsDialog(BuildContext context, CollectionItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AssignProductsToCollectionDialog(collection: item),
    );
  }

  void _confirmDeactivateCollection(BuildContext context, CollectionItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Deactivate Collection',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to deactivate "${item.name}"?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This collection will be marked inactive and hidden from storefront buyers. Products assigned to it will retain their assignment metadata.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
              ),
              child: Text(
                'DELETE /api/v1/admin/collections/${item.id}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<CollectionBloc>().add(DeactivateCollection(item.id));
            },
            child: Text(
              'Deactivate',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final cardBgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);

    return MultiBlocListener(
      listeners: [
        BlocListener<CollectionBloc, CollectionState>(
          listenWhen: (prev, curr) =>
              prev.deactivatedCollection != curr.deactivatedCollection &&
              curr.deactivatedCollection != null,
          listener: (context, state) {
            final deactivated = state.deactivatedCollection!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Collection "${deactivated.name}" deactivated successfully.',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.all(20),
              ),
            );
          },
        ),
        BlocListener<CollectionBloc, CollectionState>(
          listenWhen: (prev, curr) =>
              prev.deactivateError != curr.deactivateError &&
              curr.deactivateError != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to deactivate collection: ${state.deactivateError}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.all(20),
              ),
            );
          },
        ),
      ],
      child: BlocBuilder<CollectionBloc, CollectionState>(
      builder: (context, state) {
        final allItems = state.collections;
        final filteredItems = allItems.where((c) {
          if (_searchQuery.isEmpty) return true;
          final matchName = c.name.toLowerCase().contains(_searchQuery);
          final matchSlug = c.slug.toLowerCase().contains(_searchQuery);
          final matchDesc = c.description.toLowerCase().contains(_searchQuery);
          final matchSubs = c.subCollections.any((s) =>
              s.name.toLowerCase().contains(_searchQuery) ||
              s.slug.toLowerCase().contains(_searchQuery));
          return matchName || matchSlug || matchDesc || matchSubs;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header & Actions Row
              _buildHeader(context, state, isDark, borderColor),

              const SizedBox(height: 20),

              // 2. Overview Metrics Row
              _buildMetricsRow(state, isDark, surfaceColor, borderColor),

              const SizedBox(height: 24),

              // 3. Search & Filter Bar
              _buildSearchBar(isDark, surfaceColor, borderColor),

              const SizedBox(height: 20),

              // 4. Content Area: Loading, Error, Empty, or Collections List
              if (state.status == CollectionStatus.loading && allItems.isEmpty)
                _buildLoadingState(isDark)
              else if (state.status == CollectionStatus.error && allItems.isEmpty)
                _buildErrorState(context, state.errorMessage ?? 'Failed to load collections', isDark, surfaceColor, borderColor)
              else if (filteredItems.isEmpty)
                _buildEmptyState(isDark, surfaceColor, borderColor)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredItems.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    // By default, expand if user expanded or if it has subcollections and less than 3 total collections
                    final isExpanded = _expandedCollectionIds.contains(item.id) ||
                        (_searchQuery.isNotEmpty && item.subCollections.isNotEmpty);
                    return _buildCollectionCard(item, isExpanded, isDark, surfaceColor, borderColor, cardBgColor);
                  },
                ),
            ],
          ),
        );
      },
    ),
  );
}

  Widget _buildHeader(BuildContext context, CollectionState state, bool isDark, Color borderColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.collections_bookmark_rounded,
                      color: Color(0xFF059669),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Storefront Collections & Taxonomy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 42),
                child: Text(
                  'Manage top-level curated collections, seasonal crop categories, and pest & disease navigation paths.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                context.read<CollectionBloc>().add(const FetchCollections(isRefresh: true));
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Sync Collections',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF059669),
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _openCreateCollectionDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Create Collection',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsRow(CollectionState state, bool isDark, Color surfaceColor, Color borderColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final count = state.totalCollections;
        final subCount = state.totalSubCollections;
        final activeCount = state.activeCollectionsCount;
        final mappedProducts = state.totalMappedProducts;

        final items = [
          _buildMetricCard(
            title: 'Total Collections',
            value: '$count',
            subtitle: 'Root groupings active',
            icon: Icons.category_rounded,
            iconColor: const Color(0xFF2563EB),
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildMetricCard(
            title: 'Sub-Collections',
            value: '$subCount',
            subtitle: 'Leaf filter nodes',
            icon: Icons.subdirectory_arrow_right_rounded,
            iconColor: const Color(0xFF7C3AED),
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildMetricCard(
            title: 'Live Published',
            value: '$activeCount',
            subtitle: 'Storefront visible',
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF059669),
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildMetricCard(
            title: 'Mapped Products',
            value: '$mappedProducts',
            subtitle: 'Catalog SKU linkages',
            icon: Icons.inventory_2_rounded,
            iconColor: const Color(0xFFD97706),
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        ];

        if (isCompact) {
          return GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: items,
          );
        }

        return Row(
          children: items
              .map((it) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: it)))
              .toList(),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color surfaceColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          icon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 20),
          hintText: 'Search collections by title, slug, or child sub-collection names (e.g. Rice, Maize, Aphids)...',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  onPressed: () => _searchController.clear(),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCollectionCard(
    CollectionItem item,
    bool isExpanded,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color cardBgColor,
  ) {
    final hasSubs = item.subCollections.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Main Card Tap Target
          InkWell(
            onTap: () => _toggleExpanded(item.id),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority Badge / Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Text(
                        '#${item.priority}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Title, Slug & Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            // Slug Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '/${item.slug}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            if (item.bannerTitle != null && item.bannerTitle!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Banner: ${item.bannerTitle}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Status, Count & Expansion Controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sub-Collection Count Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          '${item.subCollections.length} Sub-Collections',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Product Count Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          '${item.productCount} Products',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Active Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (item.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.isActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: item.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),

                      IconButton(
                        icon: const Icon(Icons.playlist_add_rounded, size: 20),
                        tooltip: 'Assign Products',
                        color: const Color(0xFF059669),
                        onPressed: () => _openAssignProductsDialog(context, item),
                      ),

                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Edit Collection',
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        onPressed: () => _openEditCollectionDialog(context, item),
                      ),

                      if (item.isActive)
                        IconButton(
                          icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                          tooltip: 'Deactivate Collection',
                          color: const Color(0xFFEF4444),
                          onPressed: () => _confirmDeactivateCollection(context, item),
                        ),

                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Sub-Collections Shelf
          if (isExpanded) ...[
            Divider(height: 1, color: borderColor),
            Container(
              padding: const EdgeInsets.all(18),
              color: cardBgColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_tree_outlined, size: 16, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 6),
                      Text(
                        'Mapped Sub-Collections & Category Taxonomy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!hasSubs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No sub-collections mapped. This is a direct single-level product collection.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: item.subCollections.map((sub) {
                        return _buildSubCollectionPill(sub, isDark, surfaceColor, borderColor);
                      }).toList(),
                    ),
                  const SizedBox(height: 18),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 16),

                  // Assigned Products Shelf
                  BlocBuilder<ProductBloc, ProductState>(
                    builder: (context, prodState) {
                      final allSubIds = item.subCollections.map((s) => s.id).toSet();
                      final assigned = prodState.products.where((p) {
                        return p.assignedCollections.contains(item.id) ||
                            p.assignedCollections.any((id) => allSubIds.contains(id));
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF059669)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Assigned Catalog Products (${assigned.length})',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _openAssignProductsDialog(context, item),
                                icon: const Icon(Icons.playlist_add_rounded, size: 15),
                                label: Text(
                                  'Assign / Manage Products',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF059669),
                                  side: const BorderSide(color: Color(0xFF059669)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (assigned.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No products assigned to this collection yet. Click "Assign / Manage Products" to link items from your catalog.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: assigned.map((p) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: AppProductImage(imageUrl: p.image, width: 24, height: 24),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 180),
                                        child: Text(
                                          p.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '₹${p.price.toStringAsFixed(0)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubCollectionPill(
    SubCollectionItem sub,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sub-collection Image or Default Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 38,
              height: 38,
              child: sub.image != null && sub.image!.isNotEmpty
                  ? AppProductImage(
                      imageUrl: sub.image!,
                      width: 38,
                      height: 38,
                      borderRadius: 6,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      child: const Center(
                        child: Icon(Icons.grass_rounded, size: 20, color: Color(0xFF059669)),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sub.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
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
                      '${sub.productCount} SKUs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sub.productCount > 0 ? const Color(0xFF059669) : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• /${sub.slug}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF059669)),
            const SizedBox(height: 14),
            Text(
              'Loading collections catalog from server...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message, bool isDark, Color surfaceColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              'Unable to Load Collections',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<CollectionBloc>().add(const FetchCollections(isRefresh: true)),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry Fetch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color surfaceColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'No collections matching "$_searchQuery"',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              'Try clearing your search query or check spelling.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
