import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UsersView extends StatelessWidget {
  final int activeSubTabIndex; // 0 = Sellers, 1 = Customers
  final ValueChanged<int> onSubTabChanged;
  final Widget child;
  final int sellersCount;
  final int customersCount;
  final bool isWide;

  const UsersView({
    super.key,
    required this.activeSubTabIndex,
    required this.onSubTabChanged,
    required this.child,
    required this.sellersCount,
    required this.customersCount,
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
        // Unified Users Top Segmented Tabs Bar
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
                  title: 'Sellers',
                  count: sellersCount,
                  icon: Icons.storefront_rounded,
                  isSelected: activeSubTabIndex == 0,
                  isDark: isDark,
                  onTap: () => onSubTabChanged(0),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildSegmentButton(
                  title: 'Customers',
                  count: customersCount,
                  icon: Icons.people_alt_rounded,
                  isSelected: activeSubTabIndex == 1,
                  isDark: isDark,
                  onTap: () => onSubTabChanged(1),
                ),
              ),
            ],
          ),
        ),

        // Active View Content (Sellers or Customers)
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
            color: isSelected ? const Color(0xFF059669) : Colors.transparent,
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
