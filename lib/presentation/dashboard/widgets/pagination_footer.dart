import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaginationFooter extends StatelessWidget {
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final int rowsPerPage;
  final List<int> rowsPerPageOptions;
  final int startIndex;
  final int endIndex;
  final bool isDark;
  final Color surfaceColor;
  final Color borderColor;
  final bool isWide;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsPerPageChanged;

  const PaginationFooter({
    super.key,
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.rowsPerPage,
    this.rowsPerPageOptions = const [5, 10, 20, 50],
    required this.startIndex,
    required this.endIndex,
    required this.isDark,
    required this.surfaceColor,
    required this.borderColor,
    required this.isWide,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startDisplay = totalItems == 0 ? 0 : startIndex + 1;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: isWide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Count & Rows Per Page Selector
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Showing $startDisplay - $endIndex of $totalItems products',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Rows per page:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: rowsPerPage,
                          isDense: true,
                          dropdownColor: surfaceColor,
                          icon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          items: rowsPerPageOptions.map((n) {
                            return DropdownMenuItem<int>(
                              value: n,
                              child: Text('$n'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              onRowsPerPageChanged(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Right: Navigation Buttons & Numerical Page Pills
                _buildPaginationControls(),
              ],
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$startDisplay-$endIndex of $totalItems',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rows:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          height: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: rowsPerPage,
                              isDense: true,
                              dropdownColor: surfaceColor,
                              icon: const Icon(Icons.arrow_drop_down_rounded, size: 16),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              items: rowsPerPageOptions.map((n) {
                                return DropdownMenuItem<int>(
                                  value: n,
                                  child: Text('$n'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  onRowsPerPageChanged(val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildPaginationControls(),
              ],
            ),
    );
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // First Page Button
        _buildPageNavButton(
          icon: Icons.first_page_rounded,
          tooltip: 'First Page',
          enabled: currentPage > 1,
          onTap: () => onPageChanged(1),
        ),
        const SizedBox(width: 4),

        // Previous Page Button
        _buildPageNavButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous Page',
          enabled: currentPage > 1,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        const SizedBox(width: 6),

        // Numerical Page Buttons (with smart windowing)
        ...List.generate(totalPages, (index) {
          final pageNum = index + 1;
          if (totalPages > 5) {
            if (pageNum != 1 && pageNum != totalPages && (pageNum < currentPage - 1 || pageNum > currentPage + 1)) {
              if (pageNum == currentPage - 2 || pageNum == currentPage + 2) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    '...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }
          }

          final isActive = pageNum == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => onPageChanged(pageNum),
              child: Container(
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF059669) : surfaceColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive ? const Color(0xFF059669) : borderColor,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$pageNum',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(width: 6),

        // Next Page Button
        _buildPageNavButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next Page',
          enabled: currentPage < totalPages,
          onTap: () => onPageChanged(currentPage + 1),
        ),
        const SizedBox(width: 4),

        // Last Page Button
        _buildPageNavButton(
          icon: Icons.last_page_rounded,
          tooltip: 'Last Page',
          enabled: currentPage < totalPages,
          onTap: () => onPageChanged(totalPages),
        ),
      ],
    );
  }

  Widget _buildPageNavButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor),
            color: enabled
                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF1F5F9)),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: enabled
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
            ),
          ),
        ),
      ),
    );
  }
}
