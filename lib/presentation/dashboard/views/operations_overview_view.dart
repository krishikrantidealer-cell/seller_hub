import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/models/product.dart';

class OperationsOverviewView extends StatelessWidget {
  final List<Product> products;
  final VoidCallback? onViewAllOrders;

  const OperationsOverviewView({
    super.key,
    required this.products,
    this.onViewAllOrders,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final lowStockCount = products.where((p) => p.stock < 50).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  value: '128',
                  trend: '+12.4% vs yesterday',
                  trendPositive: true,
                  icon: Icons.shopping_bag_outlined,
                  iconColor: const Color(0xFF10B981),
                ),
                _buildKpiCard(
                  width: cardWidth,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  title: 'Gross Dispatch Value',
                  value: '₹4,82,950',
                  trend: '+8.2% this week',
                  trendPositive: true,
                  icon: Icons.currency_rupee_rounded,
                  iconColor: const Color(0xFF3B82F6),
                ),
                _buildKpiCard(
                  width: cardWidth,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  title: 'Pending Dispatches',
                  value: '34 batches',
                  trend: 'Within 24h SLA',
                  trendPositive: true,
                  icon: Icons.local_shipping_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                ),
                _buildKpiCard(
                  width: cardWidth,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  title: 'Low Stock SKUs',
                  value: '$lowStockCount items',
                  trend: 'Requires stock reorder',
                  trendPositive: false,
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFF59E0B),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // Recent Dispatches Card
        Container(
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
                          'Recent Logistics Dispatches & Fulfillments',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Latest dealer fulfillments routed via multi-carrier logistics',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: onViewAllOrders ?? () {},
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF059669)),
                    label: Text(
                      'View All Orders',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDispatchRow(
                isDark: isDark,
                borderColor: borderColor,
                orderId: 'ORD-AGRI-9921',
                dealer: 'Kisan Seva Kendra, Nashik',
                category: 'Insecticide • Chlorpyrifos 20% EC',
                amount: '₹34,800',
                status: 'Ready to Dispatch',
                statusColor: const Color(0xFF059669),
              ),
              _buildDispatchRow(
                isDark: isDark,
                borderColor: borderColor,
                orderId: 'ORD-AGRI-9918',
                dealer: 'Shree Agro Traders, Rajkot',
                category: 'Hybrid Seed • Cotton BG-II 450g',
                amount: '₹72,400',
                status: 'Carrier In-Transit',
                statusColor: const Color(0xFF2563EB),
              ),
              _buildDispatchRow(
                isDark: isDark,
                borderColor: borderColor,
                orderId: 'ORD-AGRI-9904',
                dealer: 'Annadata Krishi Kendra, Indore',
                category: 'Bio-Fertilizer • Zinc Micronutrient 5L',
                amount: '₹18,500',
                status: 'Processing',
                statusColor: const Color(0xFFD97706),
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
  }) {
    return Container(
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
                    fontSize: 12.5,
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
    );
  }

  Widget _buildDispatchRow({
    required bool isDark,
    required Color borderColor,
    required String orderId,
    required String dealer,
    required String category,
    required String amount,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderId,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  dealer,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              category,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
