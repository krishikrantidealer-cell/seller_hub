import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/constants/api_endpoints.dart';
import 'package:seller_hub/core/di/injection_container.dart';
import 'package:seller_hub/core/models/order.dart';
import 'package:seller_hub/core/utils/file_download_helper.dart';

class OrderDetailView extends StatefulWidget {
  final MarketplaceOrder order;
  final VoidCallback onBack;
  final ValueChanged<MarketplaceOrder>? onOrderUpdated;

  const OrderDetailView({
    super.key,
    required this.order,
    required this.onBack,
    this.onOrderUpdated,
  });

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  bool _isBusy = false;

  MarketplaceOrder get order => widget.order;
  VoidCallback get onBack => widget.onBack;
  ValueChanged<MarketplaceOrder>? get onOrderUpdated => widget.onOrderUpdated;

  Future<void> _runOrderPostAction({
    required String path,
    required String successMessage,
  }) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final res = await InjectionContainer.instance.apiClient.post(
        path,
        requiresAuth: true,
      );
      final data = res['data'];
      if (data is Map) {
        final updated = MarketplaceOrder.fromBackendJson(Map<String, dynamic>.from(data));
        onOrderUpdated?.call(updated);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _downloadLabelAndMarkPacked() async {
    if (_isBusy || !order.hasLabel) return;
    setState(() => _isBusy = true);
    try {
      final res = await InjectionContainer.instance.apiClient.get(
        ApiEndpoints.adminOrderLabel(order.id),
        requiresAuth: true,
      );
      final data = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : <String, dynamic>{};
      final pdfBase64 = data['pdfBase64']?.toString() ?? '';
      final newStatus = data['overallStatus']?.toString() ?? order.orderStatus;
      final transitioned = data['transitionedToPacked'] == true;

      if (newStatus != order.orderStatus) {
        onOrderUpdated?.call(order.copyWith(orderStatus: newStatus));
      }

      if (pdfBase64.isNotEmpty) {
        final pdfBytes = base64Decode(pdfBase64);
        downloadBytes(pdfBytes, 'Delhivery_Label_${order.orderNumber}.pdf');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            transitioned
                ? 'Delhivery label downloaded — order marked PACKED.'
                : 'Delhivery label opened for printing.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final softWhiteSurface = isDark ? const Color(0xFF111827) : const Color(0xFFFAFBFD);
    final insetSurface = isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FB);
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final cardShadow = isDark
        ? <BoxShadow>[]
        : const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ];

    final payColor = _getPaymentStatusColor(order.paymentStatus);
    final statusColor = _getOrderStatusColor(order.orderStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navigation & Action Bar
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(
                'Back to Orders',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const Spacer(),
            // Progressive Delhivery One Fulfillment Action Bar
            // Print/Download Label button is strictly hidden until backend has stored the label (order.hasLabel == true).
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (order.orderStatus.toUpperCase() == 'PENDING' ||
                    order.orderStatus.toUpperCase() == 'PENDING_PAYMENT')
                  ElevatedButton.icon(
                    onPressed: _isBusy
                        ? null
                        : () => _runOrderPostAction(
                              path: ApiEndpoints.adminOrderConfirm(order.id),
                              successMessage: 'Order ${order.orderNumber} marked CONFIRMED.',
                            ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: Text(
                      'Confirm Order',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                if (order.orderStatus.toUpperCase() == 'CONFIRMED' && !order.hasLabel)
                  ElevatedButton.icon(
                    onPressed: _isBusy
                        ? null
                        : () => _runOrderPostAction(
                              path: ApiEndpoints.adminOrderDelhiveryShipment(order.id),
                              successMessage: 'Delhivery One AWB & shipping label generated.',
                            ),
                    icon: const Icon(Icons.local_shipping_rounded, size: 16),
                    label: Text(
                      'Check Delhivery Label',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                if (order.hasLabel)
                  ElevatedButton.icon(
                    onPressed: _isBusy ? null : _downloadLabelAndMarkPacked,
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: Text(
                      order.orderStatus.toUpperCase() == 'CONFIRMED'
                          ? 'Download Label & Mark Packed'
                          : 'Print Shipping Label',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                if (order.shippingAddress.trackingNumber.trim().isNotEmpty &&
                    order.orderStatus.toUpperCase() != 'DELIVERED' &&
                    order.orderStatus.toUpperCase() != 'CANCELLED')
                  OutlinedButton.icon(
                    onPressed: _isBusy
                        ? null
                        : () => _runOrderPostAction(
                              path: ApiEndpoints.adminOrderSyncTracking(order.id),
                              successMessage: 'Delhivery One tracking synced.',
                            ),
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: Text(
                      'Sync Delhivery Tracking',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                if ((order.orderStatus.toUpperCase() == 'RTO_DELIVERED' ||
                        order.orderStatus.toUpperCase() == 'RETURNED') &&
                    !order.rtoRestocked)
                  ElevatedButton.icon(
                    onPressed: _isBusy
                        ? null
                        : () => _runOrderPostAction(
                              path: ApiEndpoints.adminOrderRtoRestock(order.id),
                              successMessage: 'RTO return verified and inventory restocked.',
                            ),
                    icon: const Icon(Icons.inventory_rounded, size: 16),
                    label: Text(
                      'Verify RTO & Restock',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Order Summary Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_rounded,
                      color: Color(0xFF059669),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order.orderNumber,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Order Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                order.orderStatus,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Payment Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: payColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: payColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'PAYMENT: ${order.paymentStatus}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: payColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Company: ${order.company} • Sold by: ${order.sellerName} • Placed on: ${_formatDate(order.orderDate)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Section 0.5: Modern Visual Fulfillment Stepper
        _buildFulfillmentStepper(order, isDark, softWhiteSurface, borderColor),

        const SizedBox(height: 18),

        // Section 1: 2-Column Modern Bento Grid (Order & Payment Overview + Delhivery One Fulfillment)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                  boxShadow: cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF059669)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Order & Payment Overview',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(height: 1, color: borderColor),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 28,
                      runSpacing: 14,
                      children: [
                        _buildMetaItem('ORDER NUMBER', order.orderNumber, isDark),
                        _buildMetaItem('ORDER DATE', _formatDate(order.orderDate), isDark),
                        _buildMetaItem('PAYMENT METHOD', order.paymentMethod, isDark),
                        _buildMetaItem('PAYMENT STATUS', order.paymentStatus, isDark, highlightColor: payColor),
                        _buildMetaItem('PAID DATE', order.paymentStatus == 'PAID' ? _formatDate(order.paidDate) : '—', isDark),
                        _buildMetaItem('COMPANY / CHANNEL', order.company, isDark),
                        _buildMetaItem('GATEWAY TXN REF', order.referenceBankDetail.utrNumber, isDark, highlightColor: const Color(0xFF059669)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: softWhiteSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                  boxShadow: cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_shipping_rounded, size: 16, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Delhivery One Fulfillment & SLA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(height: 1, color: borderColor),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 28,
                      runSpacing: 14,
                      children: [
                        _buildMetaItem(
                          'COURIER PARTNER',
                          order.shippingAddress.carrier.isNotEmpty ? order.shippingAddress.carrier : 'DELHIVERY ONE',
                          isDark,
                        ),
                        _buildMetaItem(
                          'AWB / WAYBILL',
                          order.shippingAddress.trackingNumber.isNotEmpty
                              ? order.shippingAddress.trackingNumber
                              : 'Awaiting Dispatch Booking',
                          isDark,
                          highlightColor: order.shippingAddress.trackingNumber.isNotEmpty
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFD97706),
                        ),
                        _buildMetaItem(
                          'LABEL STATUS',
                          order.hasLabel ? 'Label Stored & Ready' : 'Not Available Yet',
                          isDark,
                          highlightColor: order.hasLabel ? const Color(0xFF059669) : const Color(0xFFD97706),
                        ),
                        _buildMetaItem('DISPATCH SLA (H:M)', order.dispatchDurationFormatted, isDark),
                        _buildMetaItem('SELLER', order.sellerName, isDark, highlightColor: const Color(0xFF2563EB)),
                        if (order.rtoReason.isNotEmpty)
                          _buildMetaItem('RTO REASON', order.rtoReason, isDark, highlightColor: const Color(0xFFEA580C)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Section 2: Actual Order Products (Line Items)
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, size: 18, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Text(
                      'Actual Order Products (${order.items.length} Items)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),

              // Desktop Header Strip
              Container(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Expanded(flex: 5, child: _buildTableHeaderText('PRODUCT & COMPOSITION', isDark)),
                    Expanded(flex: 2, child: _buildTableHeaderText('SKU & PACK', isDark)),
                    Expanded(flex: 2, child: _buildTableHeaderText('UNIT PRICE / MRP', isDark)),
                    Expanded(flex: 2, child: _buildTableHeaderText('QUANTITY', isDark)),
                    Expanded(flex: 2, child: _buildTableHeaderText('SELLER WILL GET', isDark)),
                    Expanded(flex: 2, child: _buildTableHeaderText('LINE TOTAL', isDark, alignRight: true)),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),

              // Line Items
              ...order.items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
                  ),
                  child: Row(
                    children: [
                      // Product Title & SKU
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: item.imageUrl.trim().isNotEmpty
                                  ? Image.network(
                                      item.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.agriculture_rounded,
                                        color: Color(0xFF059669),
                                        size: 18,
                                      ),
                                    )
                                  : const Icon(Icons.agriculture_rounded, color: Color(0xFF059669), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.productCode} • ${item.technicalName}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // SKU & Pack
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productCode.isNotEmpty ? item.productCode : 'Standard SKU',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.packSize} ${item.unit} ${item.packUnit}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Unit Price
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${item.unitPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'MRP ₹${item.mrp.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quantity
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${item.quantity} Qty',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),

                      // Seller Will Get (SWG)
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.sellerWillGet > 0
                              ? '₹${item.sellerWillGet.toStringAsFixed(2)}'
                              : '—',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: item.sellerWillGet > 0
                                ? const Color(0xFF059669)
                                : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          ),
                        ),
                      ),

                      // Line Total
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '₹${item.totalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Financial Ledger Summary Box
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 360,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: insetSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Subtotal', '₹${order.subtotal.toStringAsFixed(2)}', isDark),
                          const SizedBox(height: 6),
                          _buildSummaryRow('GST Tax Total', '+₹${order.gstAmount.toStringAsFixed(2)}', isDark),
                          const SizedBox(height: 6),
                          _buildSummaryRow('Freight & Shipping Fee', '+₹${order.shippingFee.toStringAsFixed(2)}', isDark),
                          const SizedBox(height: 6),
                          if (order.discountAmount > 0) ...[
                            _buildSummaryRow('Discount Applied', '-₹${order.discountAmount.toStringAsFixed(2)}', isDark, isDiscount: true),
                            const SizedBox(height: 6),
                          ],
                          Divider(color: borderColor),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Grand Total:',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₹${order.grandTotal.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Section 3: Contact Details (3-Column Grid: Billing Address, Shipping Address, Seller Details)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.contact_mail_outlined, size: 18, color: Color(0xFF059669)),
                  const SizedBox(width: 8),
                  Text(
                    'Contact Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column 1: Billing Address
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: softWhiteSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Billing Address',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildStripedAddressRow('Name :', order.billingAddress.recipientName, isDark, shaded: false, isBold: true),
                          _buildStripedAddressRow('Address :', order.billingAddress.addressLine, isDark, shaded: true),
                          _buildStripedAddressRow('Pincode :', order.billingAddress.pincode, isDark, shaded: false),
                          _buildStripedAddressRow('City :', order.billingAddress.city, isDark, shaded: true),
                          _buildStripedAddressRow('Taluka / Tehsil :', order.billingAddress.taluka, isDark, shaded: false),
                          _buildStripedAddressRow('District :', order.billingAddress.district, isDark, shaded: true),
                          _buildStripedAddressRow('State :', order.billingAddress.state, isDark, shaded: false, isBold: true),
                          if (order.billingAddress.gstin.isNotEmpty)
                            _buildStripedAddressRow('Buyer GSTIN :', order.billingAddress.gstin, isDark, shaded: true),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Column 2: Shipping Address
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: insetSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Shipping Address',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildStripedAddressRow('Name :', order.shippingAddress.recipientName, isDark, shaded: false, isBold: true),
                          _buildStripedAddressRow('Phone :', order.shippingAddress.phone, isDark, shaded: true),
                          _buildStripedAddressRow('Address :', order.shippingAddress.addressLine, isDark, shaded: false),
                          _buildStripedAddressRow('Pincode :', order.shippingAddress.pincode, isDark, shaded: true),
                          _buildStripedAddressRow('City :', order.shippingAddress.city, isDark, shaded: false),
                          _buildStripedAddressRow('Taluka / Tehsil :', order.shippingAddress.taluka, isDark, shaded: true),
                          _buildStripedAddressRow('District :', order.shippingAddress.district, isDark, shaded: false),
                          _buildStripedAddressRow('State :', order.shippingAddress.state, isDark, shaded: true, isBold: true),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Column 3: Seller Details
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: softWhiteSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Seller Details',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildStripedAddressRow('Name :', order.sellerDetails.tradeName, isDark, shaded: false, isBold: true),
                          _buildStripedAddressRow('Email :', order.sellerDetails.contactEmail, isDark, shaded: true),
                          _buildStripedAddressRow('Mobile Number :', order.sellerDetails.contactPhone, isDark, shaded: false),
                          _buildStripedAddressRow('GSTIN :', order.sellerDetails.gstin, isDark, shaded: true),
                          _buildStripedAddressRow('Net Amount :', '₹${order.grandTotal.toStringAsFixed(2)}', isDark, shaded: false, isBold: true),
                          _buildStripedAddressRow('Seller Will Get :', order.sellerWillGet > 0 ? '₹${order.sellerWillGet.toStringAsFixed(2)}' : '—', isDark, shaded: true, isBold: true),
                          _buildStripedAddressRow('Seller Payment :', order.sellerPaymentStatus, isDark, shaded: false, isBold: true),
                          _buildStripedAddressRow('Seller Pay Date :', order.sellerPaymentDate != null ? _formatDate(order.sellerPaymentDate!) : '—', isDark, shaded: true),
                          _buildStripedAddressRow('Courier :', order.shippingAddress.carrier.isNotEmpty ? order.shippingAddress.carrier : 'Delhivery One', isDark, shaded: false),
                          _buildStripedAddressRow('Dispatch Pin :', order.sellerDetails.pincode, isDark, shaded: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFulfillmentStepper(
    MarketplaceOrder order,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    final s = order.orderStatus.toUpperCase();
    final isRto = s.startsWith('RTO') || s == 'RETURNED';
    final isCancelled = s == 'CANCELLED';

    int activeStep = 0;
    if (s == 'CONFIRMED') activeStep = 1;
    if (s == 'PACKED') activeStep = 2;
    if (s == 'SHIPPED' || s == 'IN_TRANSIT' || s == 'IN TRANSIT' || s == 'OUT_FOR_DELIVERY') activeStep = 3;
    if (s == 'DELIVERED' || isRto) activeStep = 4;

    final steps = [
      ('Order Placed', Icons.shopping_bag_outlined),
      ('Confirmed', Icons.verified_outlined),
      ('Packed & Label', Icons.inventory_2_outlined),
      ('In Transit', Icons.local_shipping_outlined),
      (isRto ? 'RTO' : (isCancelled ? 'Cancelled' : 'Delivered'), isRto ? Icons.assignment_return_outlined : Icons.check_circle_outline),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (idx) {
          if (idx.isOdd) {
            final stepLeft = idx ~/ 2;
            final completed = !isCancelled && activeStep > stepLeft;
            return Expanded(
              child: Container(
                height: 2.5,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: completed
                      ? (isRto && stepLeft >= 3 ? const Color(0xFFEA580C) : const Color(0xFF059669))
                      : borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          final stepIndex = idx ~/ 2;
          final (label, icon) = steps[stepIndex];
          final isDone = !isCancelled && activeStep >= stepIndex;
          final isCurrent = !isCancelled && activeStep == stepIndex;
          final color = (isCancelled && stepIndex == 4)
              ? const Color(0xFFDC2626)
              : (isRto && stepIndex == 4)
                  ? const Color(0xFFEA580C)
                  : (isDone ? const Color(0xFF059669) : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)));

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isDone ? color.withValues(alpha: 0.14) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: isCurrent ? 2 : 1.2),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: isDone ? (isDark ? Colors.white : const Color(0xFF0F172A)) : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStripedAddressRow(
    String label,
    String value,
    bool isDark, {
    required bool shaded,
    bool isBold = false,
  }) {
    final hairline = isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: hairline, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, bool isDark, {Color? highlightColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isNotEmpty ? value : '—',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: highlightColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderText(String title, bool isDark, {bool alignRight = false}) {
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

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isDiscount
                ? const Color(0xFF059669)
                : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }
}
