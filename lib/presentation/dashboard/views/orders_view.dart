import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/models/order.dart';
import 'package:seller_hub/presentation/dashboard/widgets/pagination_footer.dart';

class OrdersView extends StatefulWidget {
  final List<MarketplaceOrder> orders;
  final ValueChanged<MarketplaceOrder> onSelectOrder;

  const OrdersView({
    super.key,
    required this.orders,
    required this.onSelectOrder,
  });

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  String _searchQuery = '';
  String _selectedSeller = 'All Sellers';
  // ignore: prefer_final_fields
  String _selectedStatus = 'All Statuses';
  // ignore: prefer_final_fields
  String _selectedPaymentStatus = 'All Payments';

  int _currentPage = 1;
  int _rowsPerPage = 10;
  final List<int> _rowsPerPageOptions = const [5, 10, 20, 50];

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return const Color(0xFF059669);
      case 'PENDING':
        return const Color(0xFFD97706);
      case 'FAILED':
        return const Color(0xFFDC2626);
      case 'REFUNDED':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF059669);
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return const Color(0xFF059669);
      case 'IN TRANSIT':
        return const Color(0xFF2563EB);
      case 'READY TO DISPATCH':
        return const Color(0xFF0D9488);
      case 'PROCESSING':
        return const Color(0xFFD97706);
      case 'CANCELLED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF059669);
    }
  }

  List<String> get _sellerOptions {
    final s = <String>{'All Sellers'};
    for (final o in widget.orders) {
      s.add(o.sellerName);
    }
    return s.toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    // Filtering logic
    final filtered = widget.orders.where((o) {
      final matchesSearch = _searchQuery.isEmpty ||
          o.orderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.shippingAddress.recipientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.shippingAddress.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.sellerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.referenceBankDetail.utrNumber.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesSeller = _selectedSeller == 'All Sellers' || o.sellerName == _selectedSeller;
      final matchesStatus = _selectedStatus == 'All Statuses' || o.orderStatus.toLowerCase() == _selectedStatus.toLowerCase();
      final matchesPayment = _selectedPaymentStatus == 'All Payments' || o.paymentStatus.toLowerCase() == _selectedPaymentStatus.toLowerCase();

      return matchesSearch && matchesSeller && matchesStatus && matchesPayment;
    }).toList();

    // Pagination calculations
    final totalItems = filtered.length;
    final totalPages = totalItems > 0 ? (totalItems / _rowsPerPage).ceil() : 1;
    final safePage = _currentPage.clamp(1, totalPages);
    final startIndex = totalItems == 0 ? 0 : (safePage - 1) * _rowsPerPage;
    final endIndex = totalItems == 0 ? 0 : (startIndex + _rowsPerPage > totalItems ? totalItems : startIndex + _rowsPerPage);
    final paginatedOrders = totalItems == 0 ? <MarketplaceOrder>[] : filtered.sublist(startIndex, endIndex);

    final totalRevenue = widget.orders
        .where((o) => o.paymentStatus == 'PAID')
        .fold<double>(0.0, (sum, o) => sum + o.grandTotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Metrics Row
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
                  title: 'Total Platform Orders',
                  value: '${widget.orders.length}',
                  trend: 'All multi-tenant orders',
                  icon: Icons.receipt_long_rounded,
                  iconColor: const Color(0xFF059669),
                ),
                _buildKpiCard(
                  width: cardWidth,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  title: 'Settled Order Value',
                  value: '₹${totalRevenue.toStringAsFixed(0)}',
                  trend: 'UTR verified bank payouts',
                  icon: Icons.currency_rupee_rounded,
                  iconColor: const Color(0xFF3B82F6),
                ),
                _buildKpiCard(
                  width: cardWidth,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  title: 'Active In-Transit',
                  value: '${widget.orders.where((o) => o.orderStatus == 'IN TRANSIT').length}',
                  trend: 'Multi-carrier freight logistics',
                  icon: Icons.local_shipping_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                ),
                _buildKpiCard(
                  width: cardWidth,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  title: 'Ready to Dispatch',
                  value: '${widget.orders.where((o) => o.orderStatus == 'READY TO DISPATCH').length}',
                  trend: 'Packed in warehouse',
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFFD97706),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // Search & Filter Controls
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  onChanged: (val) => setState(() {
                    _searchQuery = val.trim();
                    _currentPage = 1;
                  }),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by Order Number, Customer, City, Seller, Company or UTR...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    filled: true,
                    fillColor: surfaceColor,
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
                      borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Seller Filter Dropdown
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSeller,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  dropdownColor: surfaceColor,
                  items: _sellerOptions.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedSeller = val;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Status Filter Chips Strip
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: const [
              'All Statuses',
              'PROCESSING',
              'READY TO DISPATCH',
              'IN TRANSIT',
              'DELIVERED',
              'CANCELLED',
            ].map((status) {
              final isSelected = _selectedStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  label: Text(status),
                  selected: isSelected,
                  selectedColor: isDark
                      ? const Color(0xFF059669).withValues(alpha: 0.22)
                      : const Color(0xFF059669).withValues(alpha: 0.12),
                  backgroundColor: surfaceColor,
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF059669) : borderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  onSelected: (_) => setState(() {
                    _selectedStatus = status;
                    _currentPage = 1;
                  }),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Orders Master Table Container
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Table Header Strip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      'Multi-Tenant Order & Dispatch Ledger',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${filtered.length} Orders',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),

              // Table Column Headers
              Container(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: _buildColHeader('ORDER & DATE', isDark)),
                    Expanded(flex: 3, child: _buildColHeader('CUSTOMER & LOCATION', isDark)),
                    Expanded(flex: 3, child: _buildColHeader('SELLER & COMPANY', isDark)),
                    Expanded(flex: 2, child: _buildColHeader('PAYMENT METHOD', isDark)),
                    Expanded(flex: 2, child: _buildColHeader('BANK UTR REF', isDark)),
                    Expanded(flex: 2, child: _buildColHeader('AMOUNT & ITEMS', isDark)),
                    SizedBox(width: 90, child: _buildColHeader('STATUS', isDark)),
                    const SizedBox(width: 16),
                    SizedBox(width: 88, child: _buildColHeader('ACTIONS', isDark, alignRight: true)),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),

              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'No orders matching the current filter criteria.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),

              // Order Rows
              ...paginatedOrders.map((o) {
                final payCol = _getPaymentStatusColor(o.paymentStatus);
                final statCol = _getOrderStatusColor(o.orderStatus);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
                  ),
                  child: Row(
                    children: [
                      // 1. Order Number & Date
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
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(o.orderDate),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. Customer & Location
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.shippingAddress.recipientName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${o.shippingAddress.city}, ${o.shippingAddress.state}',
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

                      // 3. Seller & Company
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.sellerName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2563EB),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              o.company,
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

                      // 4. Payment Method & Status
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: payCol.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                o.paymentStatus,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: payCol,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              o.paymentMethod,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // 5. Reference Bank UTR
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.referenceBankDetail.bankName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              o.referenceBankDetail.utrNumber,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // 6. Amount & Items
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${o.grandTotal.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${o.items.length} Product${o.items.length > 1 ? 's' : ''}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 7. Order Status
                      SizedBox(
                        width: 90,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statCol.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statCol.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              o.orderStatus,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: statCol,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // 8. Actions
                      SizedBox(
                        width: 88,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // View button
                            Tooltip(
                              message: 'View Order',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => widget.onSelectOrder(o),
                                child: Container(
                                  width: 32,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF059669).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 15,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Print / Download Invoice button
                            Tooltip(
                              message: 'Download Invoice',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Downloading invoice for ${o.orderNumber}…',
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                                      ),
                                      backgroundColor: const Color(0xFF2563EB),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      margin: const EdgeInsets.all(20),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 32,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.print_rounded,
                                    size: 15,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Pagination Footer
              PaginationFooter(
                totalItems: totalItems,
                currentPage: safePage,
                totalPages: totalPages,
                rowsPerPage: _rowsPerPage,
                rowsPerPageOptions: _rowsPerPageOptions,
                startIndex: startIndex,
                endIndex: endIndex,
                isDark: isDark,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                isWide: true,
                onPageChanged: (newPage) => setState(() => _currentPage = newPage),
                onRowsPerPageChanged: (newRows) => setState(() {
                  _rowsPerPage = newRows;
                  _currentPage = 1;
                }),
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
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  trend,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColHeader(String title, bool isDark, {bool alignRight = false}) {
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
