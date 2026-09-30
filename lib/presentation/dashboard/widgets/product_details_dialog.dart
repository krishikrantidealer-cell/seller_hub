import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/product.dart';

class ProductDetailsDialog extends StatefulWidget {
  final Product product;

  const ProductDetailsDialog({super.key, required this.product});

  @override
  State<ProductDetailsDialog> createState() => _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends State<ProductDetailsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF161E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final p = widget.product;

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
                    ),
                    child: const Center(
                      child: Icon(Icons.inventory_2_rounded, color: Color(0xFF059669), size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (p.isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.isAvailable ? 'Available' : 'Unavailable',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: p.isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                            /*
                            // isFeatured badge temporarily commented out
                            if (p.isFeatured) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Featured',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            */
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.productCode} • HSN: ${p.hsnCode} • ${p.technicalName}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF059669),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF059669),
                unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                indicatorColor: const Color(0xFF059669),
                indicatorWeight: 3,
                labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'General & Specs'),
                  Tab(text: 'Agronomy & Usage'),
                  Tab(text: 'Pricing & GST'),
                  Tab(text: 'Inventory & Shipping'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: General & Specs
                  _buildGeneralTab(context, isDark, borderColor),

                  // Tab 2: Agronomy & Usage
                  _buildAgronomyTab(context, isDark, borderColor),

                  // Tab 3: Pricing & GST
                  _buildPricingTab(context, isDark, borderColor),

                  // Tab 4: Inventory & Shipping
                  _buildLogisticsTab(context, isDark, borderColor),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        '${p.ratings.toStringAsFixed(1)} / 5.0 Rating',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Vendor: ${p.vendor}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab(BuildContext context, bool isDark, Color borderColor) {
    final p = widget.product;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Product Code', p.productCode, 'HSN Code', p.hsnCode, isDark),
          _buildInfoRow('Technical Name', p.technicalName, 'Vendor / Brand', p.vendor, isDark),
          _buildInfoRow('Category', p.category, 'Collections', p.collections, isDark),
          _buildInfoRow('Sub Collections', p.subCollections, 'Variant', p.variant, isDark),
          _buildInfoRow('Pack Size', '${p.packSize} ${p.unit}', 'Refund Policy', p.refundPolicy, isDark),
          const SizedBox(height: 16),
          Text(
            'Product Description',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Features',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.features,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Benefits',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.benefits,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgronomyTab(BuildContext context, bool isDark, Color borderColor) {
    final p = widget.product;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Technical Content', p.technicalContent, 'Mode of Action', p.modeOfAction, isDark),
          _buildInfoRow('Suitable Crops', p.suitableCrop, 'Dosage', p.dosage, isDark),
          _buildInfoRow('Application Method', p.applicationMethod, 'Target Pests', p.targetPests, isDark),
          _buildInfoRow('Target Diseases', p.targetDiseases, 'Category Group', p.category, isDark),
        ],
      ),
    );
  }

  Widget _buildPricingTab(BuildContext context, bool isDark, Color borderColor) {
    final p = widget.product;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Display Rate (Selling Price)', '₹${p.displayRate.toStringAsFixed(2)}',
            'Printed MRP', '₹${p.printedMrp.toStringAsFixed(2)}',
            isDark,
            highlightFirst: true,
          ),
          _buildInfoRow(
            'Cost Price (To Seller)', '₹${p.costPrice.toStringAsFixed(2)}',
            'Discount in Rs', '₹${p.discountRs.toStringAsFixed(2)}',
            isDark,
          ),
          _buildInfoRow(
            'Discount Percentage', '${p.discountPercentage.toStringAsFixed(1)}%',
            'GST Rate', '${p.gst.toStringAsFixed(0)}%',
            isDark,
          ),
          _buildInfoRow(
            'Unit of Measurement', p.unit,
            'Pack Size', p.packSize,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsTab(BuildContext context, bool isDark, Color borderColor) {
    final p = widget.product;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Current Stock Quantity', '${p.stock} Units',
            'Stock Availability', p.isAvailable ? 'In Stock / Ready' : 'Out of Stock',
            isDark,
            highlightFirst: true,
          ),
          _buildInfoRow(
            'Shipped By Partner', p.shippedBy,
            'Standard Wire Gauge / SWG', p.swg,
            isDark,
          ),
          _buildInfoRow(
            'Product Shipping Weight', '${p.productWeight} ${p.productWeightUnit}',
            'Package Dimensions (LxWxH)', p.dimensions,
            isDark,
          ),
          _buildInfoRow(
            'Product Status', p.status,
            'Refund & Return Terms', p.refundPolicy,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label1, String value1,
    String label2, String value2,
    bool isDark, {
    bool highlightFirst = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label1,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value1.isEmpty ? '—' : value1,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: highlightFirst ? FontWeight.w800 : FontWeight.w600,
                    color: highlightFirst 
                        ? const Color(0xFF059669) 
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label2,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value2.isEmpty ? '—' : value2,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
