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
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);

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
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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

        // Section 1: Order Metadata & Reference Bank Details
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
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFF059669)),
                  const SizedBox(width: 8),
                  Text(
                    'Order Commercial & Bank Settlement Terms',
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
              const SizedBox(height: 16),

              Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  _buildMetaItem('ORDER NUMBER', order.orderNumber, isDark),
                  _buildMetaItem('ORDER DATE', _formatDate(order.orderDate), isDark),
                  _buildMetaItem('PAID DATE', _formatDate(order.paidDate), isDark),
                  _buildMetaItem('PAYMENT METHOD', order.paymentMethod, isDark),
                  _buildMetaItem('PAYMENT STATUS', order.paymentStatus, isDark, highlightColor: payColor),
                  _buildMetaItem('COMPANY', order.company, isDark),
                  _buildMetaItem('SELLER NAME', order.sellerName, isDark, highlightColor: const Color(0xFF2563EB)),
                ],
              ),

              const SizedBox(height: 18),

              // Reference Bank Detail Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping_rounded, size: 16, color: Color(0xFF059669)),
                        const SizedBox(width: 8),
                        Text(
                          'Delhivery One Fulfillment & Gateway Settlement',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        _buildMetaItem(
                          'COURIER PARTNER',
                          order.shippingAddress.carrier.isNotEmpty
                              ? order.shippingAddress.carrier
                              : 'DELHIVERY ONE',
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
                        _buildMetaItem('GATEWAY', order.referenceBankDetail.bankName, isDark),
                        _buildMetaItem(
                          'GATEWAY TXN REF',
                          order.referenceBankDetail.utrNumber,
                          isDark,
                          highlightColor: const Color(0xFF059669),
                        ),
                        if (order.rtoReason.isNotEmpty)
                          _buildMetaItem(
                            'RTO REASON',
                            order.rtoReason,
                            isDark,
                            highlightColor: const Color(0xFFEA580C),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                    Expanded(flex: 2, child: _buildTableHeaderText('GST TAX', isDark)),
                    Expanded(flex: 2, child: _buildTableHeaderText('QUANTITY', isDark)),
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
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.agriculture_rounded, color: Color(0xFF059669), size: 18),
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

                      // GST
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${item.gstPercentage.toStringAsFixed(0)}% GST',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          ),
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
                    SizedBox(
                      width: 320,
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
                              Text(
                                'Grand Total:',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
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

        // Section 3: Contact Data (1. Seller Details, 2. Shipping & Billing Address)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Seller Details
            Expanded(
              child: Container(
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
                      children: [
                        const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Text(
                          '1. Seller Details',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: borderColor),
                    const SizedBox(height: 12),
                    _buildContactItem('Trade Name', order.sellerDetails.tradeName, isDark, isBold: true),
                    _buildContactItem('Legal Entity', order.sellerDetails.legalEntityName, isDark),
                    _buildContactItem('Seller ID', order.sellerDetails.sellerId, isDark),
                    _buildContactItem('GSTIN', order.sellerDetails.gstin, isDark),
                    _buildContactItem('PAN', order.sellerDetails.panNumber, isDark),
                    _buildContactItem('Dispatch Contact', order.sellerDetails.contactPhone, isDark),
                    _buildContactItem('Support Email', order.sellerDetails.contactEmail, isDark),
                    _buildContactItem('Warehouse Hub', '${order.sellerDetails.warehouseAddress}, ${order.sellerDetails.city}, ${order.sellerDetails.state} - ${order.sellerDetails.pincode}', isDark),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Card 2: Shipping & Billing Address
            Expanded(
              child: Container(
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
                      children: [
                        const Icon(Icons.local_shipping_rounded, size: 18, color: Color(0xFF059669)),
                        const SizedBox(width: 8),
                        Text(
                          '2. Shipping & Billing Address',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: borderColor),
                    const SizedBox(height: 12),

                    // Shipping Address Subsection
                    Text(
                      'SHIPPING ADDRESS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: const Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildContactItem('Consignee', '${order.shippingAddress.recipientName} (${order.shippingAddress.companyName})', isDark, isBold: true),
                    _buildContactItem('Delivery Phone', order.shippingAddress.phone, isDark),
                    _buildContactItem('Address', '${order.shippingAddress.addressLine}, ${order.shippingAddress.city}, ${order.shippingAddress.state} - ${order.shippingAddress.pincode}', isDark),
                    _buildContactItem('Logistics Carrier', '${order.shippingAddress.carrier} (AWB: ${order.shippingAddress.trackingNumber})', isDark),
                    _buildContactItem('Shipment Status', order.shippingAddress.deliveryStatus, isDark, highlightColor: const Color(0xFF2563EB)),

                    const SizedBox(height: 12),
                    Divider(height: 1, color: borderColor),
                    const SizedBox(height: 12),

                    // Billing Address Subsection
                    Text(
                      'BILLING ADDRESS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildContactItem('Entity Name', order.billingAddress.companyName, isDark, isBold: true),
                    if (order.billingAddress.gstin.isNotEmpty)
                      _buildContactItem('Buyer GSTIN', order.billingAddress.gstin, isDark),
                    _buildContactItem('Billing Address', '${order.billingAddress.addressLine}, ${order.billingAddress.city}, ${order.billingAddress.state} - ${order.billingAddress.pincode}', isDark),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Section 4: Live Delhivery Tracking & Order Status History Timeline
        _buildTimelineSection(order, isDark, surfaceColor, borderColor),

        const SizedBox(height: 32),
      ],
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

  Widget _buildContactItem(String label, String value, bool isDark, {bool isBold = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: highlightColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(
    MarketplaceOrder order,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    final trackingEvents = order.trackingEvents.reversed.toList();
    final statusHistory = order.statusHistory.reversed.toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Live Delhivery Tracking Scans
        Expanded(
          child: Container(
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
                  children: [
                    const Icon(Icons.radar_rounded, size: 18, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Text(
                      'Live Delhivery Tracking Scans (${trackingEvents.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 12),
                if (trackingEvents.isEmpty)
                  Text(
                    'No Delhivery scan events yet. Scans populate automatically once dispatch books the shipment in Delhivery One.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  )
                else
                  ...List.generate(trackingEvents.length, (i) {
                    final ev = trackingEvents[i];
                    final subtitleParts = <String>[
                      if (ev.location.isNotEmpty) ev.location,
                      if (ev.instructions.isNotEmpty) ev.instructions,
                    ];
                    return _buildTimelineRow(
                      title: ev.statusType.isNotEmpty ? '${ev.status} (${ev.statusType})' : ev.status,
                      subtitle: subtitleParts.join(' • '),
                      timestamp: ev.scannedAt != null ? _formatDate(ev.scannedAt!) : '—',
                      accentColor: const Color(0xFF059669),
                      isLast: i == trackingEvents.length - 1,
                      isDark: isDark,
                    );
                  }),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Card 2: Order Lifecycle Status History
        Expanded(
          child: Container(
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
                  children: [
                    const Icon(Icons.history_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      'Order Lifecycle Status History (${statusHistory.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 12),
                if (statusHistory.isEmpty)
                  _buildTimelineRow(
                    title: order.orderStatus,
                    subtitle: 'Order placed via ${order.paymentMethod}',
                    timestamp: _formatDate(order.orderDate),
                    accentColor: const Color(0xFF2563EB),
                    isLast: true,
                    isDark: isDark,
                  )
                else
                  ...List.generate(statusHistory.length, (i) {
                    final ev = statusHistory[i];
                    final subtitleParts = <String>[
                      if (ev.actor.isNotEmpty) 'By ${ev.actor}',
                      if (ev.note.isNotEmpty) ev.note,
                    ];
                    return _buildTimelineRow(
                      title: ev.status,
                      subtitle: subtitleParts.join(' • '),
                      timestamp: ev.occurredAt != null ? _formatDate(ev.occurredAt!) : '—',
                      accentColor: const Color(0xFF2563EB),
                      isLast: i == statusHistory.length - 1,
                      isDark: isDark,
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineRow({
    required String title,
    required String subtitle,
    required String timestamp,
    required Color accentColor,
    required bool isLast,
    required bool isDark,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title.isNotEmpty ? title : 'UPDATE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Text(
                      timestamp,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
