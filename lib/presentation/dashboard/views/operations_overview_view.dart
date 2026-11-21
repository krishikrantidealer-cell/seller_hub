import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/models/order.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/core/models/seller.dart';

class OperationsOverviewView extends StatefulWidget {
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
  State<OperationsOverviewView> createState() => _OperationsOverviewViewState();
}

class _OperationsOverviewViewState extends State<OperationsOverviewView> {
  String? _hoveredKpiKey;
  String? _hoveredOrderId;
  int? _hoveredBarIdx;

  String _formatInr(double value) {
    final rounded = value.round();
    final s = rounded.toString();
    if (s.length <= 3) return '₹$s';
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final formattedRest = rest.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+$)'),
      (m) => '${m[1]},',
    );
    return '₹$formattedRest,$last3';
  }

  String _formatShortTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]}, $h12:$min $amPm';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'PENDING_PAYMENT':
        return const Color(0xFFD97706);
      case 'CONFIRMED':
      case 'PROCESSING':
        return const Color(0xFF0284C7);
      case 'PACKED':
      case 'READY TO DISPATCH':
        return const Color(0xFF4F46E5);
      case 'SHIPPED':
      case 'IN_TRANSIT':
      case 'IN TRANSIT':
      case 'OUT_FOR_DELIVERY':
        return const Color(0xFF7C3AED);
      case 'DELIVERED':
        return const Color(0xFF059669);
      case 'RTO_INITIATED':
      case 'RTO_IN_TRANSIT':
      case 'RTO_DELIVERED':
      case 'RETURNED':
        return const Color(0xFFEA580C);
      case 'CANCELLED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF059669);
    }
  }

  int _dispatchPriority(MarketplaceOrder o) {
    final s = o.orderStatus.toUpperCase();
    if (s == 'PENDING' || s == 'PENDING_PAYMENT') return 0;
    if (s == 'CONFIRMED' && !o.hasLabel) return 1;
    if (s == 'CONFIRMED') return 2;
    if (s == 'PACKED') return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final softWhite = isDark ? const Color(0xFF111827) : const Color(0xFFFAFBFD);
    final insetSurface = isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FB);
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final cardShadow = isDark
        ? <BoxShadow>[]
        : const [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayOrders = widget.orders.where((o) {
      final od = DateTime(o.orderDate.year, o.orderDate.month, o.orderDate.day);
      return od == today;
    }).toList();
    final todayGmv = todayOrders.fold<double>(0.0, (s, o) => s + o.grandTotal);

    final paidOrders = widget.orders.where((o) => o.paymentStatus.toUpperCase() == 'PAID').toList();
    final settledRevenue = paidOrders.fold<double>(0.0, (sum, o) => sum + o.grandTotal);
    final aov = widget.orders.isEmpty
        ? 0.0
        : widget.orders.fold<double>(0.0, (s, o) => s + o.grandTotal) / widget.orders.length;

    final pendingCount = widget.orders.where((o) {
      final s = o.orderStatus.toUpperCase();
      return s == 'PENDING' || s == 'PENDING_PAYMENT';
    }).length;
    final confirmedCount = widget.orders.where((o) {
      final s = o.orderStatus.toUpperCase();
      return s == 'CONFIRMED' || s == 'PROCESSING';
    }).length;
    final packedCount = widget.orders.where((o) => o.orderStatus.toUpperCase() == 'PACKED').length;
    final inTransitCount = widget.orders.where((o) {
      final s = o.orderStatus.toUpperCase();
      return s == 'SHIPPED' || s == 'IN_TRANSIT' || s == 'IN TRANSIT' || s == 'OUT_FOR_DELIVERY';
    }).length;
    final deliveredCount = widget.orders.where((o) => o.orderStatus.toUpperCase() == 'DELIVERED').length;
    final rtoOrCancelledCount = widget.orders.where((o) {
      final s = o.orderStatus.toUpperCase();
      return s.startsWith('RTO') || s == 'RETURNED' || s == 'CANCELLED';
    }).length;
    final awaitingBookingCount = widget.orders.where((o) {
      final s = o.orderStatus.toUpperCase();
      return s == 'CONFIRMED' && !o.hasLabel;
    }).length;

    final lowStockProducts = widget.products.where((p) => p.stock < 50).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    // Priority dispatch queue: actionable orders first, then newest
    final priorityOrders = [...widget.orders]..sort((a, b) {
        final p = _dispatchPriority(a).compareTo(_dispatchPriority(b));
        if (p != 0) return p;
        return b.orderDate.compareTo(a.orderDate);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Compact Action & Alert Strip
        _buildCompactTopStrip(
          isDark: isDark,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          pendingCount: pendingCount,
          awaitingBookingCount: awaitingBookingCount,
          lowStockCount: lowStockProducts.length,
        ),

        const SizedBox(height: 12),

        // 2. 4 Compact KPI Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 1060 ? 4 : (constraints.maxWidth >= 600 ? 2 : 1);
            const gap = 12.0;
            final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                _buildCompactKpiCard(
                  keyId: 'today',
                  width: cardWidth,
                  label: "TODAY'S GMV",
                  valueTarget: todayGmv,
                  isCurrency: true,
                  meta: '${todayOrders.length} orders today • AOV ${_formatInr(aov)}',
                  pillText: '${todayOrders.length} Today',
                  accent: const Color(0xFF059669),
                  icon: Icons.today_rounded,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  cardShadow: cardShadow,
                  onTap: widget.onNavigateToOrders,
                ),
                _buildCompactKpiCard(
                  keyId: 'settled',
                  width: cardWidth,
                  label: 'SETTLED REVENUE',
                  valueTarget: settledRevenue,
                  isCurrency: true,
                  meta: '${paidOrders.length}/${widget.orders.length} orders paid',
                  pillText: widget.orders.isEmpty
                      ? '0% Paid'
                      : '${((paidOrders.length / widget.orders.length) * 100).round()}% Paid',
                  accent: const Color(0xFF2563EB),
                  icon: Icons.payments_rounded,
                  isDark: isDark,
                  surfaceColor: softWhite,
                  borderColor: borderColor,
                  cardShadow: cardShadow,
                  onTap: widget.onNavigateToOrders,
                ),
                _buildCompactKpiCard(
                  keyId: 'action',
                  width: cardWidth,
                  label: 'DISPATCH ACTION NEEDED',
                  valueTarget: (pendingCount + confirmedCount + packedCount).toDouble(),
                  isCurrency: false,
                  meta: '$pendingCount pending • $confirmedCount confirmed • $packedCount packed',
                  pillText: awaitingBookingCount > 0 ? '$awaitingBookingCount Unbooked' : 'Ready',
                  accent: const Color(0xFFD97706),
                  icon: Icons.pending_actions_rounded,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  cardShadow: cardShadow,
                  onTap: widget.onNavigateToOrders,
                ),
                _buildCompactKpiCard(
                  keyId: 'transit',
                  width: cardWidth,
                  label: 'DELHIVERY TRANSIT',
                  valueTarget: inTransitCount.toDouble(),
                  isCurrency: false,
                  meta: '$deliveredCount delivered • $rtoOrCancelledCount RTO / cancelled',
                  pillText: '$deliveredCount Done',
                  accent: const Color(0xFF7C3AED),
                  icon: Icons.local_shipping_rounded,
                  isDark: isDark,
                  surfaceColor: softWhite,
                  borderColor: borderColor,
                  cardShadow: cardShadow,
                  onTap: widget.onNavigateToOrders,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 12),

        // 3. Main Aligned Workspace: Priority Dispatch Queue (Left 7) + Velocity & Pipeline (Right 5)
        LayoutBuilder(
          builder: (context, constraints) {
            final twoCol = constraints.maxWidth >= 920;
            final dispatchCard = _buildPriorityDispatchCard(
              isDark: isDark,
              surfaceColor: surfaceColor,
              insetSurface: insetSurface,
              borderColor: borderColor,
              cardShadow: cardShadow,
              orders: priorityOrders.take(6).toList(),
            );
            final analyticsCard = _buildVelocityAndPipelineCard(
              isDark: isDark,
              surfaceColor: softWhite,
              insetSurface: insetSurface,
              borderColor: borderColor,
              cardShadow: cardShadow,
              pending: pendingCount,
              confirmed: confirmedCount,
              packed: packedCount,
              inTransit: inTransitCount,
              delivered: deliveredCount,
              rtoOrCancelled: rtoOrCancelledCount,
            );

            if (twoCol) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 7, child: dispatchCard),
                    const SizedBox(width: 12),
                    Expanded(flex: 5, child: analyticsCard),
                  ],
                ),
              );
            }
            return Column(
              children: [
                dispatchCard,
                const SizedBox(height: 12),
                analyticsCard,
              ],
            );
          },
        ),

        const SizedBox(height: 12),

        // 4. Aligned Bottom Row: Low Stock Watch (Left 6) + Top Sellers by GMV (Right 6)
        LayoutBuilder(
          builder: (context, constraints) {
            final twoCol = constraints.maxWidth >= 820;
            final lowStockCard = _buildLowStockCard(
              isDark: isDark,
              surfaceColor: softWhite,
              insetSurface: insetSurface,
              borderColor: borderColor,
              cardShadow: cardShadow,
              lowStockProducts: lowStockProducts.take(4).toList(),
            );
            final sellersCard = _buildTopSellersCard(
              isDark: isDark,
              surfaceColor: surfaceColor,
              insetSurface: insetSurface,
              borderColor: borderColor,
              cardShadow: cardShadow,
            );
            if (twoCol) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: lowStockCard),
                    const SizedBox(width: 12),
                    Expanded(child: sellersCard),
                  ],
                ),
              );
            }
            return Column(
              children: [
                lowStockCard,
                const SizedBox(height: 12),
                sellersCard,
              ],
            );
          },
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCompactTopStrip({
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required int pendingCount,
    required int awaitingBookingCount,
    required int lowStockCount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            'Live Operations',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (pendingCount > 0)
                    _buildAlertChip('$pendingCount Pending Confirm', const Color(0xFFD97706), widget.onNavigateToOrders),
                  if (awaitingBookingCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildAlertChip('$awaitingBookingCount Awaiting Delhivery', const Color(0xFF0284C7), widget.onNavigateToOrders),
                  ],
                  if (lowStockCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildAlertChip('$lowStockCount Low Stock SKUs', const Color(0xFFEA580C), widget.onNavigateToProducts),
                  ],
                  if (pendingCount == 0 && awaitingBookingCount == 0 && lowStockCount == 0)
                    _buildAlertChip('All queues clear', const Color(0xFF059669), widget.onNavigateToOrders),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: widget.onNavigateToOrders,
            icon: const Icon(Icons.receipt_long_rounded, size: 14),
            label: Text(
              'Orders',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: widget.onOpenAddProduct,
            icon: const Icon(Icons.add_rounded, size: 15),
            label: Text(
              'Add Product',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertChip(String text, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactKpiCard({
    required String keyId,
    required double width,
    required String label,
    required double valueTarget,
    required bool isCurrency,
    required String meta,
    required String pillText,
    required Color accent,
    required IconData icon,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required List<BoxShadow> cardShadow,
    required VoidCallback onTap,
  }) {
    final hovered = _hoveredKpiKey == keyId;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredKpiKey = keyId),
      onExit: (_) {
        if (_hoveredKpiKey == keyId) setState(() => _hoveredKpiKey = null);
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hovered ? accent.withValues(alpha: 0.5) : borderColor,
              width: hovered ? 1.3 : 1.0,
            ),
            boxShadow: cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 15, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      pillText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: valueTarget),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) {
                  return Text(
                    isCurrency ? _formatInr(val) : val.round().toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityDispatchCard({
    required bool isDark,
    required Color surfaceColor,
    required Color insetSurface,
    required Color borderColor,
    required List<BoxShadow> cardShadow,
    required List<MarketplaceOrder> orders,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Priority Dispatch Queue',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Pending & unbooked orders appear at the top',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: widget.onNavigateToOrders,
                child: Text(
                  'View All (${widget.orders.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (orders.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: insetSurface, borderRadius: BorderRadius.circular(8)),
              child: Center(
                child: Text(
                  'No orders yet.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ...orders.map((o) {
              final rowKey = o.id.isNotEmpty ? o.id : o.orderNumber;
              final hovered = _hoveredOrderId == rowKey;
              final statCol = _statusColor(o.orderStatus);
              final totalQty = o.items.fold<int>(0, (s, i) => s + i.quantity);

              return MouseRegion(
                onEnter: (_) => setState(() => _hoveredOrderId = rowKey),
                onExit: (_) {
                  if (_hoveredOrderId == rowKey) setState(() => _hoveredOrderId = null);
                },
                child: InkWell(
                  onTap: () => widget.onSelectOrder(o),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    margin: const EdgeInsets.only(bottom: 7),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                    decoration: BoxDecoration(
                      color: hovered ? const Color(0xFF059669).withValues(alpha: 0.05) : insetSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hovered ? const Color(0xFF059669).withValues(alpha: 0.35) : borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 28,
                          decoration: BoxDecoration(
                            color: statCol,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      o.orderNumber,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '• ${o.shippingAddress.recipientName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${o.items.length} ${o.items.length == 1 ? 'item' : 'items'} ($totalQty Qty) • ${_formatShortTime(o.orderDate)} • ${o.hasLabel ? 'Label Ready' : 'No Label'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatInr(o.grandTotal),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: statCol.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            o.orderStatus,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: statCol,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildVelocityAndPipelineCard({
    required bool isDark,
    required Color surfaceColor,
    required Color insetSurface,
    required Color borderColor,
    required List<BoxShadow> cardShadow,
    required int pending,
    required int confirmed,
    required int packed,
    required int inTransit,
    required int delivered,
    required int rtoOrCancelled,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final dayCounts = List<int>.filled(7, 0);
    final dayGmv = List<double>.filled(7, 0.0);

    for (final o in widget.orders) {
      final od = DateTime(o.orderDate.year, o.orderDate.month, o.orderDate.day);
      final diff = today.difference(od).inDays;
      if (diff >= 0 && diff < 7) {
        final idx = 6 - diff;
        dayCounts[idx] += 1;
        dayGmv[idx] += o.grandTotal;
      }
    }

    final maxGmv = dayGmv.fold<double>(0.0, (m, v) => v > m ? v : m);
    final maxCount = dayCounts.fold<int>(0, (m, v) => v > m ? v : m);
    final weekGmv = dayGmv.fold<double>(0.0, (s, v) => s + v);
    final weekOrders = dayCounts.fold<int>(0, (s, v) => s + v);

    final totalOrders = widget.orders.length;
    final stages = [
      ('Pending', pending, const Color(0xFFD97706)),
      ('Confirmed', confirmed, const Color(0xFF0284C7)),
      ('Packed', packed, const Color(0xFF4F46E5)),
      ('In Transit', inTransit, const Color(0xFF7C3AED)),
      ('Delivered', delivered, const Color(0xFF059669)),
      ('RTO / Cancel', rtoOrCancelled, const Color(0xFFEA580C)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-Day Velocity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                _hoveredBarIdx != null
                    ? '${dayCounts[_hoveredBarIdx!]} orders • ${_formatInr(dayGmv[_hoveredBarIdx!])}'
                    : '$weekOrders orders • ${_formatInr(weekGmv)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 112,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              color: insetSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final ratio = maxGmv > 0
                    ? (dayGmv[i] / maxGmv)
                    : (maxCount > 0 ? dayCounts[i] / maxCount : 0.0);
                final barH = 10.0 + (ratio * 44.0);
                final isToday = i == 6;
                final hovered = _hoveredBarIdx == i;
                return Expanded(
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoveredBarIdx = i),
                    onExit: (_) {
                      if (_hoveredBarIdx == i) setState(() => _hoveredBarIdx = null);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${dayCounts[i]}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: hovered || isToday
                                ? const Color(0xFF059669)
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: hovered ? 22 : 17,
                          height: barH,
                          decoration: BoxDecoration(
                            color: isToday || hovered
                                ? const Color(0xFF059669)
                                : const Color(0xFF059669).withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isToday ? 'Now' : dayNames[days[i].weekday - 1],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                            color: isToday
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Pipeline Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          ...stages.map((st) {
            final (label, count, color) = st;
            final ratio = totalOrders > 0 ? (count / totalOrders).clamp(0.0, 1.0) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 6,
                        color: insetSurface,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: ratio,
                            child: Container(color: color),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: count > 0 ? color : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
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

  Widget _buildLowStockCard({
    required bool isDark,
    required Color surfaceColor,
    required Color insetSurface,
    required Color borderColor,
    required List<BoxShadow> cardShadow,
    required List<Product> lowStockProducts,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low Stock Watch (< 50 Units)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: widget.onNavigateToProducts,
                child: Text(
                  'Catalog (${widget.products.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (lowStockProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: insetSurface, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF059669)),
                  const SizedBox(width: 8),
                  Text(
                    'All catalog SKUs have healthy inventory.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            )
          else
            ...lowStockProducts.map(
              (p) => Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: insetSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (p.stock <= 10 ? const Color(0xFFDC2626) : const Color(0xFFD97706))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${p.stock} left',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: p.stock <= 10 ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopSellersCard({
    required bool isDark,
    required Color surfaceColor,
    required Color insetSurface,
    required Color borderColor,
    required List<BoxShadow> cardShadow,
  }) {
    final gmvBySeller = <String, double>{};
    final countBySeller = <String, int>{};
    for (final o in widget.orders) {
      final name = o.sellerName.trim().isNotEmpty ? o.sellerName.trim() : 'Platform / EBS';
      gmvBySeller[name] = (gmvBySeller[name] ?? 0.0) + o.grandTotal;
      countBySeller[name] = (countBySeller[name] ?? 0) + 1;
    }

    final rankedSellers = [...widget.sellers]..sort((a, b) {
        final gmvCmp = (gmvBySeller[b.tradeName] ?? 0.0).compareTo(gmvBySeller[a.tradeName] ?? 0.0);
        if (gmvCmp != 0) return gmvCmp;
        return a.tradeName.compareTo(b.tradeName);
      });
    final topSellers = rankedSellers.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Sellers by Order GMV',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: widget.onNavigateToSellers,
                child: Text(
                  'All Sellers (${widget.sellers.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (topSellers.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: insetSurface, borderRadius: BorderRadius.circular(8)),
              child: Text(
                'No sellers onboarded yet.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            )
          else
            ...topSellers.map((s) {
              final gmv = gmvBySeller[s.tradeName] ?? 0.0;
              final cnt = countBySeller[s.tradeName] ?? 0;
              return InkWell(
                onTap: () => widget.onSelectSeller(s),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 7),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: insetSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 15, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.tradeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Text(
                        '$cnt orders • ${_formatInr(gmv)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
