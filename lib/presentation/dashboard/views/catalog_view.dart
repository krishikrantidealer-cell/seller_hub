import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CatalogView extends StatelessWidget {
  final int activeSubTabIndex; // 0 = Products, 1 = Collections, 2 = Categories
  final ValueChanged<int> onSubTabChanged;
  final Widget child;
  final int productsCount;
  final int collectionsCount;
  final int categoriesCount;
  final bool isWide;

  const CatalogView({
    super.key,
    required this.activeSubTabIndex,
    required this.onSubTabChanged,
    required this.child,
    required this.productsCount,
    required this.collectionsCount,
    required this.categoriesCount,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unified Catalog Top Segmented Tabs Bar
        Container(
          margin: const EdgeInsets.only(bottom: 20),
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
                  count: productsCount,
                  icon: Icons.inventory_2_rounded,
                  isSelected: activeSubTabIndex == 0,
                  isDark: isDark,
                  onTap: () => onSubTabChanged(0),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildSegmentButton(
                  title: 'Collections',
                  count: collectionsCount,
                  icon: Icons.collections_bookmark_rounded,
                  isSelected: activeSubTabIndex == 1,
                  isDark: isDark,
                  onTap: () => onSubTabChanged(1),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildSegmentButton(
                  title: 'Categories',
                  count: categoriesCount,
                  icon: Icons.account_tree_rounded,
                  isSelected: activeSubTabIndex == 2,
                  isDark: isDark,
                  onTap: () => onSubTabChanged(2),
                ),
              ),
            ],
          ),
        ),

        // Active View Content (Products, Collections, or Categories)
        child,
      ],
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
          duration: const Duration(milliseconds: 180),
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
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
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
