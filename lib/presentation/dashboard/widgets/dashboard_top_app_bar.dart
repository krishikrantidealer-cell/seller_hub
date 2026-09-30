import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/core/models/seller.dart';
import 'package:seller_hub/logic/theme/theme_bloc.dart';
import 'package:seller_hub/logic/theme/theme_event.dart';

class DashboardTopAppBar extends StatelessWidget {
  final int selectedNavIndex;
  final Product? viewingProduct;
  final SellerProfile? viewingSeller;
  final bool isWide;
  final VoidCallback onMenuPressed;

  const DashboardTopAppBar({
    super.key,
    required this.selectedNavIndex,
    this.viewingProduct,
    this.viewingSeller,
    required this.isWide,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 28 : 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          if (!isWide)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: onMenuPressed,
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedNavIndex == 0
                      ? 'Operations Overview'
                      : (selectedNavIndex == 1
                          ? (viewingProduct != null
                              ? 'Product Specification Sheet'
                              : 'Product Catalog & Inventory')
                          : (viewingSeller != null
                              ? 'Seller Profile & Commercial Terms'
                              : 'Multi-Tenant Sellers Directory')),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  selectedNavIndex == 0
                      ? 'Platform sales, order dispatches & multi-seller metrics'
                      : (selectedNavIndex == 1
                          ? (viewingProduct != null
                              ? '${viewingProduct!.productCode} • HSN: ${viewingProduct!.hsnCode} • ${viewingProduct!.technicalName}'
                              : '38-field agri schema with CIBRC chemical & HSN compliance')
                          : (viewingSeller != null
                              ? '${viewingSeller!.tradeName} • ID: ${viewingSeller!.id} • GSTIN: ${viewingSeller!.gstin}'
                              : 'Onboarded merchants, legal compliance, KYC & commission agreements')),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Operational Status Badge
          if (isWide) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Agri Cloud Connected',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
          ],

          // Theme Toggle
          IconButton(
            tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            onPressed: () {
              context.read<ThemeBloc>().add(ToggleDarkMode(isDark));
            },
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF475569),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
