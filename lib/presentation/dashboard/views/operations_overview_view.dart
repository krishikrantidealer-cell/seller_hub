import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/models/order.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/core/models/seller.dart';

class OperationsOverviewView extends StatelessWidget {
  final List<Product> products;
  final List<SellerProfile> sellers;
  final List<MarketplaceOrder> orders;
  final ValueChanged<MarketplaceOrder> onSelectOrder;
  final ValueChanged<SellerProfile> onSelectSeller;
  final VoidCallback onNavigateToProducts;
  final VoidCallback onNavigateToSellers;
  final VoidCallback onNavigateToOrders;
  final VoidCallback onOpenAddProduct;

  const OperationsOverviewView({
    super.key,
    required this.products,
    required this.sellers,
    required this.orders,
    required this.onSelectOrder,
    required this.onSelectSeller,
    required this.onNavigateToProducts,
    required this.onNavigateToSellers,
    required this.onNavigateToOrders,
    required this.onOpenAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final isWide = MediaQuery.of(context).size.width >= 960;

    // Derived operational metrics
    final totalRevenue = orders
        .where((o) => o.paymentStatus == 'PAID')
        .fold<double>(0.0, (sum, o) => sum + o.grandTotal);
    final verifiedSellersCount = sellers.where((s) => s.status == 'VERIFIED' || s.status == 'ACTIVE').length;
    final lowStockCount = products.where((p) => p.stock < 50).length;
    final inTransitCount = orders.where((o) => o.orderStatus == 'IN TRANSIT' || o.orderStatus == 'READY TO DISPATCH').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admin Quick Action & Overview Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F1E19), const Color(0xFF0D281E)]
                  : [const Color(0xFFECFDF5), const Color(0xFFE6F4EA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF059669).withValues(alpha: 0.3)
                  : const Color(0xFF059669).withValues(alpha: 0.2),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;
              final headerInfo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
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
                              'INTERNAL CONTROL CENTER',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Platform Admin Operations',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Live telemetry across ${sellers.length} sellers, ${products.length} catalog items, and ${orders.length} orders.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                ],
              );

              final actionButtons = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: onOpenAddProduct,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      'Add Product',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onNavigateToSellers,
                    icon: const Icon(Icons.storefront_rounded, size: 16),
                    label: Text(
                      'Sellers Directory',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerInfo,
                    const SizedBox(height: 14),
                    actionButtons,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: headerInfo),
                  const SizedBox(width: 16),
                  actionButtons,
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // 4 KPI Metric Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 900
                ? (constraints.maxWidth - 48) / 4
                : (constraints.maxWidth >= 600 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildKpiCard(
                  width: cardWidth,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  title: "Today's Orders",
                  value: '${orders.length}',
                  trend: '$inTransitCount active dispatches',
                  trendPositive: true,
                  icon: Icons.receipt_long_rounded,
                  iconColor: const Color(0xFF10B981),
                  onTap: onNavigateToOrders,
                ),
                _buildKpiCard(
                  width: cardWidth,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  title: 'Gross Dispatch Value',
                  value: '₹${totalRevenue.toStringAsFixed(0)}',
                  trend: 'UTR verified payouts',
                  trendPositive: true,
                  icon: Icons.currency_rupee_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  onTap: onNavigateToOrders,
                ),
                _buildKpiCard(
                  width: cardWidth,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  title: 'Onboarded Sellers',
                  value: '${sellers.length}',
                  trend: '$verifiedSellersCount KYC verified',
                  trendPositive: true,
                  icon: Icons.storefront_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  onTap: onNavigateToSellers,
                ),
                _buildKpiCard(
                  width: cardWidth,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  title: 'Low Stock SKUs',
                  value: '$lowStockCount items',
                  trend: '${products.length} total catalog items',
                  trendPositive: lowStockCount == 0,
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  onTap: onNavigateToProducts,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // Split Grid: Recent Orders & Top Sellers
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Recent Platform Orders
              Expanded(
                flex: 6,
                child: _buildRecentOrdersCard(isDark, surfaceColor, borderColor),
              ),
              const SizedBox(width: 20),
              // Right: Active Sellers Directory Quickview
              Expanded(
                flex: 4,
                child: _buildTopSellersCard(isDark, surfaceColor, borderColor),
              ),
            ],
          )
        else ...[
          _buildRecentOrdersCard(isDark, surfaceColor, borderColor),
          const SizedBox(height: 20),
          _buildTopSellersCard(isDark, surfaceColor, borderColor),
        ],

        const SizedBox(height: 24),

        // Platform Compliance & Agronomic Standards Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: const Color(0xFF059669), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Statutory Compliance & Legal Guardrails',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final colWidth = constraints.maxWidth >= 720 ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildComplianceItem(
                        width: colWidth,
                        isDark: isDark,
                        borderColor: borderColor,
                        title: 'CIBRC Chemical Licenses',
                        status: '100% Verified',
                        statusColor: const Color(0xFF059669),
                        description: 'Insecticide & fungicide registrations active across all active pesticide manufacturers.',
                      ),
                      _buildComplianceItem(
                        width: colWidth,
                        isDark: isDark,
                        borderColor: borderColor,
                        title: 'Seed Lot Germination',
                        status: 'Compliant',
                        statusColor: const Color(0xFF059669),
                        description: 'Certified purity and germination test reports recorded for hybrid seed batches.',
                      ),
                      _buildComplianceItem(
                        width: colWidth,
                        isDark: isDark,
                        borderColor: borderColor,
                        title: 'TCS & TDS Tax Reports',
                        status: 'Auto-Settled',
                        statusColor: const Color(0xFF2563EB),
                        description: 'Automated 1% Section 194-O tax deductions logged on merchant payouts.',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required double width,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required String title,
    required String value,
    required String trend,
    required bool trendPositive,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  trendPositive ? Icons.trending_up_rounded : Icons.info_outline_rounded,
                  size: 14,
                  color: trendPositive ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trend,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: trendPositive ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersCard(bool isDark, Color surfaceColor, Color borderColor) {
    final recentOrders = orders.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Platform Orders & Dispatches',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Multi-seller dispatches and live logistics tracking',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onNavigateToOrders,
                icon: const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF059669)),
                label: Text(
                  'View All',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (recentOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No orders recorded yet.',
                  style: GoogleFonts.plusJakartaSans(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
            )
          else
            ...recentOrders.map((o) {
              Color statusColor = const Color(0xFF059669);
              if (o.orderStatus.toUpperCase() == 'IN TRANSIT') statusColor = const Color(0xFF2563EB);
              if (o.orderStatus.toUpperCase() == 'PROCESSING') statusColor = const Color(0xFFD97706);
              if (o.orderStatus.toUpperCase() == 'CANCELLED') statusColor = const Color(0xFFDC2626);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: statusColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.orderNumber,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${o.shippingAddress.recipientName} • ${o.shippingAddress.city}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        o.sellerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹${o.grandTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        o.orderStatus,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'View Order',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => onSelectOrder(o),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF059669)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTopSellersCard(bool isDark, Color surfaceColor, Color borderColor) {
    final topSellers = sellers.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Onboarded Sellers',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Multi-tenant merchant directory',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onNavigateToSellers,
                icon: const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF059669)),
                label: Text(
                  'Directory',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...topSellers.map((s) {
            final sellerProductCount = products.where((p) => p.sellerId == s.id).length;
            final isVerified = s.status == 'VERIFIED' || s.status == 'ACTIVE';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (isVerified ? const Color(0xFF059669) : const Color(0xFFF59E0B)).withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        s.tradeName.isNotEmpty ? s.tradeName[0].toUpperCase() : 'S',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isVerified ? const Color(0xFF059669) : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.tradeName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$sellerProductCount SKUs • ${s.state}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'View Profile',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => onSelectSeller(s),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.visibility_rounded, size: 14, color: Color(0xFF059669)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildComplianceItem({
    required double width,
    required bool isDark,
    required Color borderColor,
    required String title,
    required String status,
    required Color statusColor,
    required String description,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              height: 1.45,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
