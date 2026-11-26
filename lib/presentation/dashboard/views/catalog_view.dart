import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Persistent, lazy-mounted tabbed shell for the Catalog workspace
/// (0 = Products, 1 = Collections, 2 = Categories).
///
/// Each tab is mounted on first visit and kept alive inside an [IndexedStack]
/// wrapped in a [RepaintBoundary] with its own independent scroll container,
/// making tab switches O(1) instant while preserving scroll position, filters,
/// search queries, and expanded tree state.
class CatalogView extends StatefulWidget {
  final int activeSubTabIndex; // 0 = Products, 1 = Collections, 2 = Categories, 3 = Banners
  final ValueChanged<int> onSubTabChanged;
  final WidgetBuilder productsBuilder;
  final WidgetBuilder collectionsBuilder;
  final WidgetBuilder categoriesBuilder;
  final WidgetBuilder bannersBuilder;
  final Widget? detailOverlay;
  final int productsCount;
  final int collectionsCount;
  final int categoriesCount;
  final bool isWide;

  const CatalogView({
    super.key,
    required this.activeSubTabIndex,
    required this.onSubTabChanged,
    required this.productsBuilder,
    required this.collectionsBuilder,
    required this.categoriesBuilder,
    required this.bannersBuilder,
    this.detailOverlay,
    required this.productsCount,
    required this.collectionsCount,
    required this.categoriesCount,
    required this.isWide,
  });

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final Set<int> _mountedTabs = {};

  @override
  void initState() {
    super.initState();
    _mountedTabs.add(widget.activeSubTabIndex.clamp(0, 3));
  }

  @override
  void didUpdateWidget(covariant CatalogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final idx = widget.activeSubTabIndex.clamp(0, 3);
    if (!_mountedTabs.contains(idx)) {
      _mountedTabs.add(idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final horizontalPad = widget.isWide ? 32.0 : 16.0;
    final activeIndex = widget.activeSubTabIndex.clamp(0, 3);
    final showOverlay = widget.detailOverlay != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pinned Unified Catalog Top Segmented Tabs Bar
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPad, 20, horizontalPad, 16),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentButton(
                    title: 'Products',
                    count: widget.productsCount,
                    icon: Icons.inventory_2_rounded,
                    isSelected: activeIndex == 0,
                    isDark: isDark,
                    onTap: () => widget.onSubTabChanged(0),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildSegmentButton(
                    title: 'Collections',
                    count: widget.collectionsCount,
                    icon: Icons.collections_bookmark_rounded,
                    isSelected: activeIndex == 1,
                    isDark: isDark,
                    onTap: () => widget.onSubTabChanged(1),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildSegmentButton(
                    title: 'Categories',
                    count: widget.categoriesCount,
                    icon: Icons.account_tree_rounded,
                    isSelected: activeIndex == 2,
                    isDark: isDark,
                    onTap: () => widget.onSubTabChanged(2),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildSegmentButton(
                    title: 'Banners',
                    count: 0,
                    icon: Icons.view_carousel_rounded,
                    isSelected: activeIndex == 3,
                    isDark: isDark,
                    onTap: () => widget.onSubTabChanged(3),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tab Body: Keep mounted tabs alive in IndexedStack; show detailOverlay on top when active
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Visibility(
                visible: !showOverlay,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: IndexedStack(
                  index: activeIndex,
                  sizing: StackFit.expand,
                  children: [
                    _buildLazyTab(
                      index: 0,
                      builder: (ctx) => SingleChildScrollView(
                        key: const PageStorageKey('catalog_products_scroll'),
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(horizontalPad, 4, horizontalPad, 24),
                        child: widget.productsBuilder(ctx),
                      ),
                    ),
                    _buildLazyTab(
                      index: 1,
                      builder: (ctx) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: widget.isWide ? 12 : 0),
                        child: widget.collectionsBuilder(ctx),
                      ),
                    ),
                    _buildLazyTab(
                      index: 2,
                      builder: (ctx) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: widget.isWide ? 12 : 0),
                        child: widget.categoriesBuilder(ctx),
                      ),
                    ),
                    _buildLazyTab(
                      index: 3,
                      builder: (ctx) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: widget.isWide ? 12 : 0),
                        child: widget.bannersBuilder(ctx),
                      ),
                    ),
                  ],
                ),
              ),
              if (showOverlay)
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(horizontalPad, 4, horizontalPad, 24),
                  child: widget.detailOverlay!,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLazyTab({
    required int index,
    required WidgetBuilder builder,
  }) {
    if (!_mountedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    return RepaintBoundary(
      key: ValueKey('catalog_tab_boundary_$index'),
      child: Builder(builder: builder),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required int count,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF059669)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                  ),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
