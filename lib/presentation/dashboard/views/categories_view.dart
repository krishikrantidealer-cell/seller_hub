import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/category.dart';
import '../../../logic/category/category_bloc.dart';
import '../../../logic/category/category_event.dart';
import '../../../logic/category/category_state.dart';
import '../widgets/app_product_image.dart';

class CategoriesView extends StatefulWidget {
  final bool isWide;

  const CategoriesView({
    super.key,
    required this.isWide,
  });

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<CategoryBloc>().add(FilterCategories(_searchController.text));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('protection') || lower.contains('insecticide')) {
      return const Color(0xFFD97706);
    } else if (lower.contains('nutrition') || lower.contains('fertilizer')) {
      return const Color(0xFF059669);
    } else if (lower.contains('seed')) {
      return const Color(0xFF0284C7);
    } else if (lower.contains('equipment') || lower.contains('tool') || lower.contains('hardware')) {
      return const Color(0xFF7C3AED);
    } else if (lower.contains('irrigation') || lower.contains('pipe')) {
      return const Color(0xFF0D9488);
    } else if (lower.contains('garden')) {
      return const Color(0xFF10B981);
    } else if (lower.contains('organic')) {
      return const Color(0xFF16A34A);
    } else if (lower.contains('cattle') || lower.contains('bird') || lower.contains('care')) {
      return const Color(0xFFEA580C);
    }
    return const Color(0xFF059669);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final cardBgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state.status == CategoryStatus.loading && state.allCategories.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(60),
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            ),
          );
        }

        final filteredItems = state.filteredTree;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Metrics Strip
            _buildMetricsRow(context, state, isDark, surfaceColor, borderColor),
            const SizedBox(height: 16),

            // 2. Search & Level Filters Toolbar
            _buildFilterToolbar(context, state, isDark, surfaceColor, borderColor, textPrimary, textSecondary),
            const SizedBox(height: 16),

            // 3. Category Tree or Filtered List
            if (state.status == CategoryStatus.error && state.allCategories.isEmpty)
              _buildErrorView(state.errorMessage ?? 'Failed to load categories', borderColor, isDark)
            else if (filteredItems.isEmpty)
              _buildEmptyView(state.searchQuery, borderColor, isDark)
            else
              _buildCategoriesContent(filteredItems, state, isDark, surfaceColor, borderColor, cardBgColor, textPrimary, textSecondary),
          ],
        );
      },
    );
  }

  Widget _buildMetricsRow(
    BuildContext context,
    CategoryState state,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 800
            ? (constraints.maxWidth - 40) / 4
            : (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildMetricCard(
              title: 'Total Taxonomy Nodes',
              value: '${state.totalCount}',
              subtitle: 'Levels 0, 1 & 2 in DB',
              icon: Icons.account_tree_rounded,
              color: const Color(0xFF059669),
              width: cardWidth,
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            _buildMetricCard(
              title: 'Major Roots (Level 0)',
              value: '${state.rootCount}',
              subtitle: 'Top-tier agri departments',
              icon: Icons.folder_special_rounded,
              color: const Color(0xFF2563EB),
              width: cardWidth,
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            _buildMetricCard(
              title: 'Sub-Categories (Level 1)',
              value: '${state.subCount}',
              subtitle: 'Direct child categories',
              icon: Icons.subdirectory_arrow_right_rounded,
              color: const Color(0xFF7C3AED),
              width: cardWidth,
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            _buildMetricCard(
              title: 'Leaf Nodes (Level 2)',
              value: '${state.leafCount}',
              subtitle: 'Finest product classifications',
              icon: Icons.eco_rounded,
              color: const Color(0xFFD97706),
              width: cardWidth,
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
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

  Widget _buildFilterToolbar(
    BuildContext context,
    CategoryState state,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
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
                      color: textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search categories by name or slug (e.g. Bio Pesticides, Seeds)...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: textSecondary,
                      ),
                      prefixIcon: Icon(Icons.search_rounded, size: 17, color: textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              tooltip: 'Clear search',
                              color: textSecondary,
                              onPressed: () {
                                _searchController.clear();
                                context.read<CategoryBloc>().add(const FilterCategories(''));
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
              const SizedBox(width: 10),

              // Expand / Collapse All
              OutlinedButton.icon(
                onPressed: () {
                  if (state.expandedCategoryIds.isEmpty) {
                    context.read<CategoryBloc>().add(const ExpandAllCategories());
                  } else {
                    context.read<CategoryBloc>().add(const CollapseAllCategories());
                  }
                },
                icon: Icon(
                  state.expandedCategoryIds.isEmpty ? Icons.unfold_more_rounded : Icons.unfold_less_rounded,
                  size: 16,
                ),
                label: Text(
                  state.expandedCategoryIds.isEmpty ? 'Expand All' : 'Collapse All',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: BorderSide(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),

              // Refresh Button
              IconButton(
                tooltip: 'Refresh Categories',
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: textSecondary,
                onPressed: () {
                  context.read<CategoryBloc>().add(const FetchCategories(isRefresh: true));
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Level Filter Tabs Strip
          Row(
            children: [
              Text(
                'Hierarchy Depth:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildLevelChip(context, label: 'All Levels (Tree View)', level: null, current: state.selectedLevelFilter),
                      const SizedBox(width: 6),
                      _buildLevelChip(context, label: 'Level 0 (Major Roots)', level: 0, current: state.selectedLevelFilter),
                      const SizedBox(width: 6),
                      _buildLevelChip(context, label: 'Level 1 (Sub-categories)', level: 1, current: state.selectedLevelFilter),
                      const SizedBox(width: 6),
                      _buildLevelChip(context, label: 'Level 2 (Leaf nodes)', level: 2, current: state.selectedLevelFilter),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelChip(
    BuildContext context, {
    required String label,
    required int? level,
    required int? current,
  }) {
    final isSelected = current == level;
    return ChoiceChip(
      label: Text(label),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF059669),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      onSelected: (val) {
        context.read<CategoryBloc>().add(SelectLevelFilter(level));
      },
    );
  }

  Widget _buildCategoriesContent(
    List<CategoryItem> items,
    CategoryState state,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color cardBgColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    // If user filtered by Level 1 or Level 2 specifically, render a fast table/flat view
    if (state.selectedLevelFilter != null && state.selectedLevelFilter != 0) {
      return _buildFlatCategoryList(items, state, isDark, surfaceColor, borderColor, textPrimary, textSecondary);
    }

    // Otherwise render the full 3-level tree
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final root = items[index];
        final isExpanded = state.expandedCategoryIds.contains(root.id);
        final color = _getCategoryColor(root.name);

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Level 0 Root Card Header
                InkWell(
                  onTap: () {
                    context.read<CategoryBloc>().add(ToggleCategoryExpanded(root.id));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Expand Icon
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 22,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 8),

                        // Thumbnail or Icon Box (supports emojis like 🌾, network images, or fallback icon)
                        _buildCategoryThumbnail(root, color, size: 38),
                        const SizedBox(width: 14),

                        // Root Name & Slug
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      root.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Level 0 Root',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '/${root.slug}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Counts Badges
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.subdirectory_arrow_right_rounded, size: 13, color: color),
                              const SizedBox(width: 4),
                              Text(
                                '${root.children.length} Sub-categories',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• ${root.totalDescendantsCount} Total',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: root.isActive
                                ? const Color(0xFF059669).withValues(alpha: 0.1)
                                : const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            root.isActive ? 'Active' : 'Inactive',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: root.isActive ? const Color(0xFF059669) : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded Section: Level 1 and Level 2
                if (isExpanded) ...[
                  Divider(height: 1, color: borderColor),
                  if (root.children.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No sub-categories defined under ${root.name}.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: cardBgColor,
                      padding: const EdgeInsets.fromLTRB(28, 12, 16, 12),
                      child: Column(
                        children: root.children.map((sub) {
                          final isSubExpanded = state.expandedCategoryIds.contains(sub.id);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              children: [
                                // Level 1 Row
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: sub.children.isNotEmpty
                                      ? () => context.read<CategoryBloc>().add(ToggleCategoryExpanded(sub.id))
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        if (sub.children.isNotEmpty)
                                          Icon(
                                            isSubExpanded
                                                ? Icons.keyboard_arrow_down_rounded
                                                : Icons.keyboard_arrow_right_rounded,
                                            size: 18,
                                            color: textSecondary,
                                          )
                                        else
                                          const SizedBox(width: 18),
                                        const SizedBox(width: 6),

                                        // Icon or Emoji
                                        sub.hasIcon
                                            ? _buildCategoryThumbnail(sub, const Color(0xFF7C3AED), size: 24, borderRadius: 5)
                                            : Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Icon(
                                                  Icons.subdirectory_arrow_right_rounded,
                                                  color: Color(0xFF7C3AED),
                                                  size: 14,
                                                ),
                                              ),
                                        const SizedBox(width: 10),

                                        // Sub Name & Slug
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                sub.name,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Level 1',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF7C3AED),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '/${sub.slug}',
                                                style: GoogleFonts.jetBrainsMono(
                                                  fontSize: 10.5,
                                                  color: textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // L2 Leaf Count Badge
                                        if (sub.children.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD97706).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${sub.children.length} leaf nodes',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFD97706),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Level 2 Leaf Nodes Strip
                                if (isSubExpanded && sub.children.isNotEmpty) ...[
                                  Divider(height: 1, color: borderColor),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(36, 8, 12, 10),
                                    color: cardBgColor,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: sub.children.map((leaf) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: surfaceColor,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: borderColor),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (leaf.hasIcon && leaf.isEmojiIcon)
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 4),
                                                  child: Text(leaf.effectiveIcon!, style: const TextStyle(fontSize: 12)),
                                                )
                                              else
                                                const Icon(Icons.eco_rounded, size: 12, color: Color(0xFF059669)),
                                              const SizedBox(width: 4),
                                              Text(
                                                leaf.name,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '(L2)',
                                                style: GoogleFonts.jetBrainsMono(
                                                  fontSize: 9.5,
                                                  color: textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlatCategoryList(
    List<CategoryItem> items,
    CategoryState state,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Showing ${items.length} categories at Level ${state.selectedLevelFilter}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
          Divider(height: 1, color: borderColor),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, index) => Divider(height: 1, color: borderColor),
            itemBuilder: (context, index) {
              final cat = items[index];
              final parent = state.categoryById[cat.parentId];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    cat.hasIcon
                        ? _buildCategoryThumbnail(cat, const Color(0xFF059669), size: 28, borderRadius: 6)
                        : Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.label_rounded, color: Color(0xFF059669), size: 16),
                          ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '/${cat.slug}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                              if (parent != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '• Parent: ${parent.name}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Level ${cat.level}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(String query, Color borderColor, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161E2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              'No categories found matching "$query"',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different keyword or reset the level filter.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryThumbnail(
    CategoryItem category,
    Color themeColor, {
    double size = 38,
    double borderRadius = 8,
  }) {
    final icon = category.effectiveIcon;
    if (icon != null && icon.isNotEmpty) {
      if (category.isEmojiIcon) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          alignment: Alignment.center,
          child: Text(
            icon,
            style: TextStyle(fontSize: size * 0.52),
          ),
        );
      }
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: AppProductImage(
            imageUrl: icon,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.category_rounded, color: themeColor, size: size * 0.52),
    );
  }

  Widget _buildErrorView(String message, Color borderColor, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161E2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<CategoryBloc>().add(const FetchCategories(isRefresh: true));
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
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
}
