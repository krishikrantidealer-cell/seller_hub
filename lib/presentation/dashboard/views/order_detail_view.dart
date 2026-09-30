import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/models/order.dart';

class OrderDetailView extends StatelessWidget {
  final MarketplaceOrder order;
  final VoidCallback onBack;
  final ValueChanged<MarketplaceOrder>? onOrderUpdated;

  const OrderDetailView({
    super.key,
    required this.order,
    required this.onBack,
    this.onOrderUpdated,
  });

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
            // Print / Export Invoice Button
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'GST Tax Invoice for ${order.orderNumber} generated successfully.',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: const Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long_rounded, size: 16),
              label: Text(
                'Download GST Invoice',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
                        const Icon(Icons.account_balance_rounded, size: 16, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Text(
                          'Reference Bank Details & Settlement Ledger',
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
                        _buildMetaItem('BANK NAME', order.referenceBankDetail.bankName, isDark),
                        _buildMetaItem('ACCOUNT NUMBER', order.referenceBankDetail.accountNumber, isDark),
                        _buildMetaItem('IFSC CODE', order.referenceBankDetail.ifscCode, isDark),
                        _buildMetaItem('UTR / TRANSACTION REF', order.referenceBankDetail.utrNumber, isDark, highlightColor: const Color(0xFF059669)),
                        _buildMetaItem('ACCOUNT HOLDER', order.referenceBankDetail.accountHolderName, isDark),
                        _buildMetaItem('BRANCH', order.referenceBankDetail.branch, isDark),
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
                    Expanded(flex: 2, child: _buildTableHeaderText('CATEGORY & PACK', isDark)),
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

                      // Category & Pack
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.category,
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
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
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
}
