import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/models/order.dart';
import 'package:seller_hub/presentation/dashboard/widgets/pagination_footer.dart';

class OrdersView extends StatefulWidget {
  final List<MarketplaceOrder> orders;
  final ValueChanged<MarketplaceOrder> onSelectOrder;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  const OrdersView({
    super.key,
    required this.orders,
    required this.onSelectOrder,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
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
  DateTime? _fromDate;
  DateTime? _toDate;

  String? _hoveredOrderId;
  final Set<String> _collapsedOrderIds = {};

  int _currentPage = 1;
  int _rowsPerPage = 10;
  final List<int> _rowsPerPageOptions = const [5, 10, 20, 50];

  void _copyValue(String label, String value) {
    if (value.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: value.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied: ${value.trim()}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hour12:$min $amPm';
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return const Color(0xFF059669);
      case 'PENDING':
      case 'COD':
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
      case 'OUT_FOR_DELIVERY':
      case 'IN_TRANSIT':
      case 'IN TRANSIT':
      case 'SHIPPED':
      case 'DISPATCHED':
        return const Color(0xFF2563EB);
      case 'PACKED':
      case 'READY TO DISPATCH':
        return const Color(0xFF0D9488);
      case 'CONFIRMED':
        return const Color(0xFF0284C7);
      case 'PENDING':
      case 'PENDING_PAYMENT':
      case 'PROCESSING':
        return const Color(0xFFD97706);
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
      final orderDay = DateTime(o.orderDate.year, o.orderDate.month, o.orderDate.day);
      final matchesFrom = _fromDate == null || !orderDay.isBefore(DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day));
      final matchesTo = _toDate == null || !orderDay.isAfter(DateTime(_toDate!.year, _toDate!.month, _toDate!.day));

      return matchesSearch && matchesSeller && matchesStatus && matchesPayment && matchesFrom && matchesTo;
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
                  value: '${widget.orders.where((o) {
                    final s = o.orderStatus.toUpperCase();
                    return s == 'SHIPPED' || s == 'IN_TRANSIT' || s == 'IN TRANSIT' || s == 'OUT_FOR_DELIVERY';
                  }).length}',
                  trend: 'Delhivery One active transit',
                  icon: Icons.local_shipping_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                ),
                _buildKpiCard(
                  width: cardWidth,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  title: 'Pending / Ready to Pack',
                  value: '${widget.orders.where((o) {
                    final s = o.orderStatus.toUpperCase();
                    return s == 'PENDING' || s == 'CONFIRMED' || s == 'PACKED';
                  }).length}',
                  trend: 'Awaiting confirm or label/pickup',
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
            const SizedBox(width: 8),
            _buildUnifiedDateFilter(isDark, surfaceColor, borderColor),
          ],
        ),

        const SizedBox(height: 10),

        // Status Filter Chips Strip (color-coded with live counts)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: const [
              ('All Statuses', 'All Statuses'),
              ('PENDING', 'Pending'),
              ('CONFIRMED', 'Confirmed'),
              ('PACKED', 'Packed'),
              ('SHIPPED', 'Shipped'),
              ('IN_TRANSIT', 'In Transit'),
              ('OUT_FOR_DELIVERY', 'Out for Delivery'),
              ('DELIVERED', 'Delivered'),
              ('RTO_INITIATED', 'RTO Initiated'),
              ('RTO_IN_TRANSIT', 'RTO In Transit'),
              ('RTO_DELIVERED', 'RTO Delivered'),
              ('CANCELLED', 'Cancelled'),
            ].map((entry) {
              final (status, displayLabel) = entry;
              final isSelected = _selectedStatus == status;
              final chipColor = status == 'All Statuses'
                  ? const Color(0xFF059669)
                  : _getOrderStatusColor(status);
              final count = status == 'All Statuses'
                  ? widget.orders.length
                  : widget.orders.where((o) => o.orderStatus.toUpperCase() == status).length;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() {
                    _selectedStatus = status;
                    _currentPage = 1;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? chipColor
                          : (isDark ? const Color(0xFF161E2E) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? chipColor
                            : (count > 0 ? chipColor.withValues(alpha: 0.35) : borderColor),
                        width: isSelected ? 1.2 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: chipColor.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : chipColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          displayLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.22)
                                  : chipColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : chipColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
                    const Spacer(),
                    if (paginatedOrders.any((o) => o.items.length > 1)) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          final multiIds = paginatedOrders
                              .where((o) => o.items.length > 1)
                              .map((o) => o.id.isNotEmpty ? o.id : o.orderNumber);
                          final allCollapsed = multiIds.every(_collapsedOrderIds.contains);
                          setState(() {
                            if (allCollapsed) {
                              _collapsedOrderIds.removeAll(multiIds);
                            } else {
                              _collapsedOrderIds.addAll(multiIds);
                            }
                          });
                        },
                        icon: Icon(
                          paginatedOrders
                                  .where((o) => o.items.length > 1)
                                  .map((o) => o.id.isNotEmpty ? o.id : o.orderNumber)
                                  .every(_collapsedOrderIds.contains)
                              ? Icons.unfold_more_rounded
                              : Icons.unfold_less_rounded,
                          size: 14,
                        ),
                        label: Text(
                          paginatedOrders
                                  .where((o) => o.items.length > 1)
                                  .map((o) => o.id.isNotEmpty ? o.id : o.orderNumber)
                                  .every(_collapsedOrderIds.contains)
                              ? 'Expand All Items'
                              : 'Compact View',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 30),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
                    if (widget.onRetry != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: widget.onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: Text(
                          'Refresh',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 30),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
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
                    Expanded(flex: 2, child: _buildColHeader('ORDER & PLACED', isDark)),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _buildColHeader('CUSTOMER', isDark)),
                    const SizedBox(width: 12),
                    Expanded(flex: 4, child: _buildColHeader('ITEMS & SELLER', isDark)),
                    const SizedBox(width: 12),
                    SizedBox(width: 68, child: _buildColHeader('QTY', isDark)),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _buildColHeader('PAYMENT & TOTAL', isDark)),
                    const SizedBox(width: 12),
                    SizedBox(width: 108, child: _buildColHeader('SELLER PAYMENT', isDark)),
                    const SizedBox(width: 12),
                    SizedBox(width: 118, child: _buildColHeader('SELLER PAY DATE', isDark)),
                    const SizedBox(width: 12),
                    SizedBox(width: 112, child: _buildColHeader('SELLER WILL GET', isDark)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildColHeader('DELHIVERY & AWB', isDark)),
                    const SizedBox(width: 12),
                    SizedBox(width: 112, child: _buildColHeader('STATUS', isDark)),
                    const SizedBox(width: 12),
                    SizedBox(width: 80, child: _buildColHeader('ACTIONS', isDark, alignRight: true)),
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
              ...paginatedOrders.asMap().entries.map(
                (entry) => _buildOrderRow(
                  entry.key,
                  entry.value,
                  isDark,
                  surfaceColor,
                  borderColor,
                ),
              ),
              // Pagination Footer
              if (widget.isLoading && widget.orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (widget.errorMessage != null && widget.orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.onRetry != null) ...[
                        const SizedBox(width: 12),
                        TextButton(onPressed: widget.onRetry, child: const Text('Retry')),
                      ],
                    ],
                  ),
                ),
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
              if (widget.hasMore && widget.onLoadMore != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: widget.isLoadingMore ? null : widget.onLoadMore,
                      icon: widget.isLoadingMore
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more_rounded, size: 16),
                      label: Text(widget.isLoadingMore ? 'Loading more orders...' : 'Load More Orders'),
                    ),
                  ),
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

  Widget _buildOrderRow(
    int rowIndex,
    MarketplaceOrder o,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    final rowKey = o.id.isNotEmpty ? o.id : o.orderNumber;
    final isHovered = _hoveredOrderId == rowKey;
    final isMulti = o.items.length > 1;
    final isExpanded = !isMulti || !_collapsedOrderIds.contains(rowKey);

    final payCol = _getPaymentStatusColor(o.paymentStatus);
    final statCol = _getOrderStatusColor(o.orderStatus);

    final zebraBg = rowIndex.isOdd
        ? (isDark ? const Color(0xFF111827).withValues(alpha: 0.45) : const Color(0xFFF8FAFC))
        : surfaceColor;
    final hoverBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4);

    final totalQty = o.items.fold<int>(0, (s, i) => s + i.quantity);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredOrderId = rowKey),
      onExit: (_) {
        if (_hoveredOrderId == rowKey) {
          setState(() => _hoveredOrderId = null);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isHovered ? hoverBg : zebraBg,
          border: Border(
            bottom: BorderSide(color: borderColor, width: 0.9),
            left: BorderSide(color: statCol, width: 3.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => widget.onSelectOrder(o),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Order Number & Date
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  o.orderNumber,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (isHovered) ...[
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _copyValue('Order Number', o.orderNumber),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 11.5,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _formatDate(o.orderDate),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 2. Customer (name only)
                    Expanded(
                      flex: 2,
                      child: Text(
                        o.shippingAddress.recipientName.isNotEmpty
                            ? o.shippingAddress.recipientName
                            : 'Customer',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 3. Items & Seller (Single item inline full title; Multi-item expandable manifest trigger)
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (o.items.isEmpty)
                              Text(
                                '—',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              )
                            else if (!isMulti) ...[
                              Text(
                                o.items.first.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (o.items.first.packUnit.trim().isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Text(
                                        o.items.first.packUnit.trim(),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  Text(
                                    [
                                      if (o.items.first.productCode.trim().isNotEmpty)
                                        o.items.first.productCode.trim(),
                                      o.sellerName,
                                    ].where((s) => s.isNotEmpty).join(' • '),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() {
                                    if (_collapsedOrderIds.contains(rowKey)) {
                                      _collapsedOrderIds.remove(rowKey);
                                    } else {
                                      _collapsedOrderIds.add(rowKey);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.layers_rounded, size: 14, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${o.items.length} Products • $totalQty Total Qty',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF2563EB),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.5 : 0.0,
                                        duration: const Duration(milliseconds: 200),
                                        child: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Seller: ${o.sellerName}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 4. Dedicated QTY Column
                    SizedBox(
                      width: 68,
                      child: o.items.isEmpty
                          ? Text(
                              '—',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    '$totalQty Qty',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                                if (isMulti) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    o.items.map((e) => '${e.quantity}').join('+'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),

                    const SizedBox(width: 12),

                    // 5. Payment & Total
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '₹${o.grandTotal.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: payCol.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  o.paymentStatus,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: payCol,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            o.paymentMethod,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 5. Seller Payment Status
                    SizedBox(
                      width: 108,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: (o.sellerPaymentStatus == 'PAID'
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFD97706))
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            o.sellerPaymentStatus,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: o.sellerPaymentStatus == 'PAID'
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 6. Seller Payment Date
                    SizedBox(
                      width: 118,
                      child: Text(
                        o.sellerPaymentDate != null
                            ? _formatDate(o.sellerPaymentDate!)
                            : '—',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: o.sellerPaymentDate != null
                              ? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B))
                              : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 7. Seller Will Get
                    SizedBox(
                      width: 112,
                      child: Text(
                        o.sellerWillGet > 0
                            ? '₹${o.sellerWillGet.toStringAsFixed(0)}'
                            : '—',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: o.sellerWillGet > 0
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // 7. Delhivery & AWB
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (o.shippingAddress.trackingNumber.trim().isNotEmpty) ...[
                            InkWell(
                              onTap: () => _copyValue('AWB Number', o.shippingAddress.trackingNumber),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      o.shippingAddress.trackingNumber.trim(),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 11,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              o.hasLabel ? 'Delhivery • Label Ready' : 'Delhivery AWB',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: o.hasLabel ? const Color(0xFF059669) : const Color(0xFF2563EB),
                              ),
                            ),
                          ] else if (o.orderStatus.toUpperCase() == 'CONFIRMED') ...[
                            Text(
                              'Awaiting Booking',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                            Text(
                              'Book in Delhivery One',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ] else ...[
                            Text(
                              '—',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 8. Order Status Badge
                    SizedBox(
                      width: 112,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statCol.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statCol.withValues(alpha: 0.28)),
                          ),
                          child: Text(
                            o.orderStatus,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: statCol,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 8. Action Buttons (Print strictly gated on backend label existence)
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: 'View Order Details',
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
                                    color: const Color(0xFF059669).withValues(alpha: 0.28),
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
                          if (o.hasLabel) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: 'Print Shipping Label',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => widget.onSelectOrder(o),
                                child: Container(
                                  width: 32,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Animated Multi-Product Packing Manifest (expanded by default for dispatch!)
            if (isMulti)
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? _buildNestedPackingManifest(o, isDark, borderColor)
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNestedPackingManifest(
    MarketplaceOrder o,
    bool isDark,
    Color borderColor,
  ) {
    final manifestBg = isDark
        ? const Color(0xFF0B1120)
        : const Color(0xFFF1F5F9).withValues(alpha: 0.65);

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      decoration: BoxDecoration(
        color: manifestBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 13, color: Color(0xFF059669)),
                const SizedBox(width: 6),
                Text(
                  'DISPATCH PACKING MANIFEST (${o.items.length} SEPARATE PRODUCTS)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
            ),
            child: Row(
              children: [
                SizedBox(width: 30, child: _buildColHeader('#', isDark)),
                Expanded(flex: 5, child: _buildColHeader('PRODUCT TITLE', isDark)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildColHeader('PACK SIZE', isDark)),
                const SizedBox(width: 12),
                SizedBox(width: 136, child: _buildColHeader('SKU', isDark)),
                const SizedBox(width: 12),
                SizedBox(width: 68, child: _buildColHeader('QTY', isDark)),
                const SizedBox(width: 12),
                SizedBox(width: 82, child: _buildColHeader('TOTAL', isDark, alignRight: true)),
              ],
            ),
          ),
          ...List.generate(o.items.length, (i) {
            final item = o.items[i];
            final isLast = i == o.items.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                border: isLast ? null : Border(bottom: BorderSide(color: borderColor, width: 0.7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '#${i + 1}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      item.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.packUnit.trim().isNotEmpty ? item.packUnit.trim() : '${item.packSize} ${item.unit}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 136,
                    child: item.productCode.trim().isNotEmpty
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                item.productCode.trim(),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          )
                        : Text(
                            '—',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 68,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${item.quantity} Qty',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 82,
                    child: Text(
                      '₹${item.totalPrice.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
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

  String _shortDate(DateTime d) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _dateFilterLabel() {
    if (_fromDate == null && _toDate == null) return 'All Dates';
    if (_fromDate != null && _toDate != null) {
      final sameDay = _fromDate!.year == _toDate!.year &&
          _fromDate!.month == _toDate!.month &&
          _fromDate!.day == _toDate!.day;
      if (sameDay) return _shortDate(_fromDate!);
      return '${_shortDate(_fromDate!)} – ${_shortDate(_toDate!)}';
    }
    if (_fromDate != null) return 'From ${_shortDate(_fromDate!)}';
    return 'Until ${_shortDate(_toDate!)}';
  }

  Widget _buildUnifiedDateFilter(bool isDark, Color surfaceColor, Color borderColor) {
    final isActive = _fromDate != null || _toDate != null;
    final label = _dateFilterLabel();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<String>(
          tooltip: 'Filter by Date or Range',
          color: surfaceColor,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: borderColor),
          ),
          onSelected: (choice) async {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            if (choice == 'all') {
              setState(() {
                _fromDate = null;
                _toDate = null;
                _currentPage = 1;
              });
            } else if (choice == 'today') {
              setState(() {
                _fromDate = today;
                _toDate = today;
                _currentPage = 1;
              });
            } else if (choice == 'yesterday') {
              final y = today.subtract(const Duration(days: 1));
              setState(() {
                _fromDate = y;
                _toDate = y;
                _currentPage = 1;
              });
            } else if (choice == 'last7') {
              setState(() {
                _fromDate = today.subtract(const Duration(days: 6));
                _toDate = today;
                _currentPage = 1;
              });
            } else if (choice == 'last30') {
              setState(() {
                _fromDate = today.subtract(const Duration(days: 29));
                _toDate = today;
                _currentPage = 1;
              });
            } else if (choice == 'single') {
              final picked = await showDatePicker(
                context: context,
                initialDate: _fromDate ?? today,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
              );
              if (picked != null && mounted) {
                setState(() {
                  _fromDate = picked;
                  _toDate = picked;
                  _currentPage = 1;
                });
              }
            } else if (choice == 'range') {
              final pickedRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
                initialDateRange: (_fromDate != null && _toDate != null)
                    ? DateTimeRange(start: _fromDate!, end: _toDate!)
                    : DateTimeRange(
                        start: today.subtract(const Duration(days: 6)),
                        end: today,
                      ),
              );
              if (pickedRange != null && mounted) {
                setState(() {
                  _fromDate = pickedRange.start;
                  _toDate = pickedRange.end;
                  _currentPage = 1;
                });
              }
            }
          },
          itemBuilder: (context) => [
            _buildDateMenuItem('all', 'All Dates', Icons.all_inclusive_rounded, isDark),
            _buildDateMenuItem('today', 'Today', Icons.today_rounded, isDark),
            _buildDateMenuItem('yesterday', 'Yesterday', Icons.history_rounded, isDark),
            _buildDateMenuItem('last7', 'Last 7 Days', Icons.date_range_rounded, isDark),
            _buildDateMenuItem('last30', 'Last 30 Days', Icons.calendar_month_rounded, isDark),
            const PopupMenuDivider(),
            _buildDateMenuItem('single', 'Pick Single Date...', Icons.event_rounded, isDark, highlight: true),
            _buildDateMenuItem('range', 'Pick Date Range...', Icons.calendar_view_week_rounded, isDark, highlight: true),
          ],
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF059669).withValues(alpha: 0.10) : surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? const Color(0xFF059669) : borderColor,
                width: isActive ? 1.3 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 15,
                  color: isActive ? const Color(0xFF059669) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? const Color(0xFF059669) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isActive ? const Color(0xFF059669) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
        if (isActive) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: 'Clear date filter',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() {
                _fromDate = null;
                _toDate = null;
                _currentPage = 1;
              }),
              child: Container(
                height: 40,
                width: 36,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  PopupMenuItem<String> _buildDateMenuItem(
    String value,
    String title,
    IconData icon,
    bool isDark, {
    bool highlight = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 38,
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: highlight
                ? const Color(0xFF059669)
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight
                  ? const Color(0xFF059669)
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
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
