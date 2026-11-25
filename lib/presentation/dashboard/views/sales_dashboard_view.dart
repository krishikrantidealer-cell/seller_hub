import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/domain/entities/auth_session.dart';
import 'package:seller_hub/core/models/order.dart';

class SalesDashboardView extends StatelessWidget {
  final AuthSession session;
  final List<MarketplaceOrder> orders;
  final int customersCount;
  final ValueChanged<MarketplaceOrder>? onSelectOrder;
  final VoidCallback? onNavigateToOrders;
  final VoidCallback? onNavigateToCustomers;

  const SalesDashboardView({
    super.key,
    required this.session,
    required this.orders,
    required this.customersCount,
    this.onSelectOrder,
    this.onNavigateToOrders,
    this.onNavigateToCustomers,
  });

  String _formatInr(double value) {
    final rounded = value.round();
    final str = rounded.toString();
    if (str.length <= 3) return '₹$str';
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final buf = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
      buf.write(rest[i]);
    }
    return '₹$buf,$lastThree';
  }

  String _permissionLabel(String code) {
    switch (code) {
      case 'DASHBOARD_VIEW':
        return 'Dashboard';
      case 'CATALOG_VIEW':
        return 'Catalog View';
      case 'CATALOG_MANAGE':
        return 'Catalog Manage';
      case 'USERS_SELLERS_VIEW':
        return 'Sellers View';
      case 'USERS_CUSTOMERS_VIEW':
        return 'Customers View';
      case 'USERS_CUSTOMERS_MANAGE':
        return 'Customers Manage';
      case 'ORDERS_VIEW':
        return 'Orders View';
      case 'ORDERS_CREATE':
        return 'Create Order';
      case 'ORDERS_MANAGE':
        return 'Orders Manage';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final canViewOrders = session.hasPermission('ORDERS_VIEW');
    final canViewCustomers = session.hasPermission('USERS_CUSTOMERS_VIEW') ||
        session.hasPermission('USERS_CUSTOMERS_MANAGE');
    final canCreateOrder = session.hasPermission('ORDERS_CREATE');

    final totalOrders = orders.length;
    final websiteOrders = orders.where((o) => !o.isPanelOrder).length;
    final panelOrders = orders.where((o) => o.isPanelOrder).length;
    final salesPanelOrders =
        orders.where((o) => o.orderSource == 'SALES_PANEL').length;
    final activeOrders = orders
        .where((o) =>
            o.orderStatus.toUpperCase() != 'CANCELLED' &&
            o.orderStatus.toUpperCase() != 'DELIVERED')
        .length;
    final totalOrderValue = orders
        .where((o) => o.orderStatus.toUpperCase() != 'CANCELLED')
        .fold<double>(0.0, (sum, o) => sum + o.grandTotal);

    final recentOrders = orders.take(8).toList();
    final fullName = session.fullName?.trim() ?? '';
    final email = session.email?.trim() ?? '';
    final agentDisplay = fullName.isNotEmpty
        ? fullName
        : (email.isNotEmpty ? email : 'Sales Agent');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome & Quick Actions Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706)
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SALES AGENT WORKSPACE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFD97706),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            email,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome back, $agentDisplay',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (canCreateOrder && onNavigateToCustomers != null)
                        ElevatedButton.icon(
                          onPressed: onNavigateToCustomers,
                          icon: const Icon(Icons.add_shopping_cart_rounded,
                              size: 16),
                          label: const Text('Create Order (Select Customer)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      if (canViewOrders && onNavigateToOrders != null)
                        OutlinedButton.icon(
                          onPressed: onNavigateToOrders,
                          icon: const Icon(Icons.receipt_long_rounded, size: 16),
                          label: const Text('All Orders'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Active Permissions:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                  ...session.permissions.map(
                    (perm) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF059669).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        _permissionLabel(perm),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // KPI Row
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 760;
            final cards = [
              _kpiCard(
                title: 'Total Orders',
                value: canViewOrders ? '$totalOrders' : '—',
                subtitle: canViewOrders
                    ? '$websiteOrders Website • $panelOrders Panel'
                    : 'Orders permission not assigned',
                icon: Icons.shopping_bag_outlined,
                color: const Color(0xFF059669),
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _kpiCard(
                title: 'Sales Panel Orders',
                value: canViewOrders ? '$salesPanelOrders' : '—',
                subtitle: canViewOrders
                    ? '$activeOrders active in pipeline'
                    : 'Orders permission not assigned',
                icon: Icons.support_agent_rounded,
                color: const Color(0xFFD97706),
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _kpiCard(
                title: 'Order Pipeline Value',
                value: canViewOrders ? _formatInr(totalOrderValue) : '—',
                subtitle: 'Non-cancelled orders total',
                icon: Icons.currency_rupee_rounded,
                color: const Color(0xFF2563EB),
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _kpiCard(
                title: 'Customers',
                value: canViewCustomers ? '$customersCount' : '—',
                subtitle: canCreateOrder
                    ? 'Ready for assisted order creation'
                    : 'Customer directory',
                icon: Icons.people_outline_rounded,
                color: const Color(0xFF7C3AED),
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ];

            if (isCompact) {
              return Column(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i < cards.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i < cards.length - 1) const SizedBox(width: 14),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Recent Orders Card
        if (canViewOrders)
          Container(
            width: double.infinity,
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
                    Text(
                      'Recent Orders',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    if (onNavigateToOrders != null)
                      TextButton(
                        onPressed: onNavigateToOrders,
                        child: const Text('View All →'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (recentOrders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No orders yet.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...recentOrders.map((o) {
                    final badgeColor = o.orderSource == 'SALES_PANEL'
                        ? const Color(0xFFD97706)
                        : (o.isPanelOrder
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF059669));
                    return InkWell(
                      onTap: onSelectOrder != null ? () => onSelectOrder!(o) : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: borderColor),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.orderNumber,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      o.sourceLabel,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: badgeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                o.shippingAddress.recipientName,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _formatInr(o.grandTotal),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                o.orderStatus,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
