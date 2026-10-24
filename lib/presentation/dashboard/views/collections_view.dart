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

  IconData _getCollectionIcon(String name, String slug) {
    final lower = (name + slug).toLowerCase();
    if (lower.contains('crop')) return Icons.eco_rounded;
    if (lower.contains('pest') || lower.contains('disease')) return Icons.pest_control_rounded;
    if (lower.contains('best') || lower.contains('seller')) return Icons.star_rounded;
    if (lower.contains('new') || lower.contains('arrival')) return Icons.auto_awesome_rounded;
    if (lower.contains('offer') || lower.contains('deal')) return Icons.local_offer_rounded;
    return Icons.folder_special_rounded;
  }

  Color _getCollectionColor(String name, String slug) {
    final lower = (name + slug).toLowerCase();
    if (lower.contains('crop')) return const Color(0xFF10B981);
    if (lower.contains('pest') || lower.contains('disease')) return const Color(0xFFEF4444);
    if (lower.contains('best') || lower.contains('seller')) return const Color(0xFFF59E0B);
    if (lower.contains('new') || lower.contains('arrival')) return const Color(0xFF8B5CF6);
    return const Color(0xFF0284C7);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final cardBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

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
      child: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, prodState) {
          return BlocBuilder<CollectionBloc, CollectionState>(
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Sleek Compact Header
                    _buildHeader(context, state, isDark, borderColor),

                    const SizedBox(height: 14),

                    // 2. Compact Overview Metrics Row
                    _buildMetricsRow(state, prodState, isDark, surfaceColor, borderColor),

                    const SizedBox(height: 14),

                    // 3. Compact Search Bar
                    _buildSearchBar(isDark, surfaceColor, borderColor),

                    const SizedBox(height: 14),

                    // 4. Content Area
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
                        separatorBuilder: (_, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isExpanded = _expandedCollectionIds.contains(item.id) ||
                              (_searchQuery.isNotEmpty && item.subCollections.isNotEmpty);
                          return _buildCollectionCard(item, prodState, isExpanded, isDark, surfaceColor, borderColor, cardBgColor);
                        },
                      ),
                  ],
                ),
              );
            },
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
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.collections_bookmark_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Storefront Collections & Taxonomy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Organize products into store shelves so buyers find them easily.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                context.read<CollectionBloc>().add(const FetchCollections(isRefresh: true));
              },
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: Text(
                'Sync Collections',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF059669),
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(0, 36),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _openCreateCollectionDialog(context),
              icon: const Icon(Icons.add_rounded, size: 17),
              label: Text(
                'Create Collection',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(0, 36),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsRow(CollectionState state, ProductState prodState, bool isDark, Color surfaceColor, Color borderColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        final count = state.totalCollections;
        final subCount = state.totalSubCollections;
        final activeCount = state.activeCollectionsCount;
        final totalAssignedCount = prodState.products.where((p) => p.assignedCollections.isNotEmpty).length;
        final mappedProducts = totalAssignedCount > 0 ? totalAssignedCount : state.totalMappedProducts;

        final items = [
          _buildCompactMetricItem(
            title: 'Total Collections',
            value: '$count',
            icon: Icons.folder_rounded,
            color: const Color(0xFF2563EB),
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildCompactMetricItem(
            title: 'Sub-Collections',
            value: '$subCount',
            icon: Icons.account_tree_rounded,
            color: const Color(0xFF7C3AED),
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildCompactMetricItem(
            title: 'Live Published',
            value: '$activeCount',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF059669),
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          _buildCompactMetricItem(
            title: 'Mapped Products',
            value: '$mappedProducts',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFFD97706),
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        ];

        if (isCompact) {
          return GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: items,
          );
        }

        return Row(
          children: items
              .map((it) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: it)))
              .toList(),
        );
      },
    );
  }

  Widget _buildCompactMetricItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Search collections by title, slug, or child categories (e.g. Rice, Pest)...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () => _searchController.clear(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(
    CollectionItem item,
    ProductState prodState,
    bool isExpanded,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color cardBgColor,
  ) {
    final hasSubs = item.subCollections.isNotEmpty;
    final allSubIds = item.subCollections.map((s) => s.id).toSet();
    final liveProductCount = prodState.products.where((p) =>
        p.assignedCollections.contains(item.id) ||
        p.assignedCollections.any((id) => allSubIds.contains(id))
    ).length;
    final displayProductCount = liveProductCount > 0 ? liveProductCount : item.productCount;
    final themeColor = _getCollectionColor(item.name, item.slug);
    final themeIcon = _getCollectionIcon(item.name, item.slug);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded ? themeColor.withValues(alpha: 0.5) : borderColor,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row / Tap Target
          InkWell(
            onTap: () => _toggleExpanded(item.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Collection Theme Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(themeIcon, color: themeColor, size: 20),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title & Friendly Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '/${item.slug}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            if (item.bannerTitle != null && item.bannerTitle!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
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
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Compact Status & Action Controls
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Sub-Collections badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '${item.subCollections.length} Sub-Collections',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ),

                      // Products count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '$displayProductCount Products',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),

                      // Active / Inactive Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: (item.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item.isActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: item.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ),

                      // Assign Products Button
                      IconButton(
                        icon: const Icon(Icons.playlist_add_rounded, size: 20),
                        tooltip: 'Assign Products',
                        color: const Color(0xFF059669),
                        onPressed: () => _openAssignProductsDialog(context, item),
                      ),

                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Edit Collection',
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        onPressed: () => _openEditCollectionDialog(context, item),
                      ),

                      // Deactivate button
                      if (item.isActive)
                        IconButton(
                          icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                          tooltip: 'Deactivate Collection',
                          color: const Color(0xFFEF4444),
                          onPressed: () => _confirmDeactivateCollection(context, item),
                        ),

                      // Expand Chevron
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Shelf
          if (isExpanded) ...[
            Divider(height: 1, color: borderColor),
            Container(
              padding: const EdgeInsets.all(14),
              color: cardBgColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sub-Collections Header
                  Row(
                    children: [
                      const Icon(Icons.account_tree_outlined, size: 15, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 6),
                      Text(
                        'Mapped Sub-Collections & Category Taxonomy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (!hasSubs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'No sub-collections mapped. Products are assigned directly to this collection.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.subCollections.map((sub) {
                        return _buildSubCollectionPill(sub, prodState, isDark, surfaceColor, borderColor);
                      }).toList(),
                    ),

                  const SizedBox(height: 14),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 12),

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
                                  const Icon(Icons.inventory_2_outlined, size: 15, color: Color(0xFF059669)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Assigned Catalog Products (${assigned.length})',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _openAssignProductsDialog(context, item),
                                icon: const Icon(Icons.tune_rounded, size: 14),
                                label: Text(
                                  'Manage Assigned Products',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF059669),
                                  side: const BorderSide(color: Color(0xFF059669)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: const Size(0, 28),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (assigned.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No products assigned yet. Click "Assign Products" to link items to this shelf.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: assigned.map((p) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                                          width: 22,
                                          height: 22,
                                          child: AppProductImage(imageUrl: p.image, width: 22, height: 22),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 160),
                                        child: Text(
                                          p.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
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
                                          fontSize: 11,
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
    ProductState prodState,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    final liveSubCount = prodState.products.where((p) =>
        p.assignedCollections.contains(sub.id)
    ).length;
    final displaySubCount = liveSubCount > 0 ? liveSubCount : sub.productCount;

    return Container(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sub-collection Image or Default Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 32,
              height: 32,
              child: sub.image != null && sub.image!.isNotEmpty
                  ? AppProductImage(
                      imageUrl: sub.image!,
                      width: 32,
                      height: 32,
                      borderRadius: 6,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      child: const Center(
                        child: Icon(Icons.grass_rounded, size: 16, color: Color(0xFF059669)),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sub.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$displaySubCount SKUs • /${sub.slug}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: displaySubCount > 0 ? const Color(0xFF059669) : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF059669)),
            const SizedBox(height: 12),
            Text(
              'Loading collections...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: Color(0xFFEF4444)),
            const SizedBox(height: 10),
            Text(
              'Unable to Load Collections',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => context.read<CollectionBloc>().add(const FetchCollections(isRefresh: true)),
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: const Text('Retry Fetch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color surfaceColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            Text(
              'No collections matching "$_searchQuery"',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              'Try clearing your search query or check spelling.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
