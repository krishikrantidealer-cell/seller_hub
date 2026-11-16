import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Displays the live discount percentage pill next to variant pricing inputs.
class LiveDiscountPill extends StatelessWidget {
  final bool hasBothPrices;
  final double? rate;
  final double? mrp;
  final double discountRs;
  final double discountPct;
  final bool isDark;
  final Color borderColor;

  const LiveDiscountPill({
    super.key,
    required this.hasBothPrices,
    required this.rate,
    required this.mrp,
    required this.discountRs,
    required this.discountPct,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final rate = this.rate;
    final mrp = this.mrp;
    final isOverMrp = hasBothPrices && (rate ?? 0) > (mrp ?? 0);
    final Color accentColor;
    final String label;

    if (hasBothPrices && discountRs > 0) {
      accentColor = const Color(0xFF059669);
      label = 'Discount: ₹${discountRs.toStringAsFixed(0)} (${discountPct.toStringAsFixed(1)}% off)';
    } else if (isOverMrp) {
      accentColor = const Color(0xFFD97706);
      label = 'Selling Price exceeds MRP';
    } else if (hasBothPrices) {
      accentColor = const Color(0xFF64748B);
      label = 'No discount (MRP = Rate)';
    } else if (rate != null && rate > 0) {
      accentColor = const Color(0xFF64748B);
      label = 'Enter MRP for discount %';
    } else {
      accentColor = const Color(0xFF64748B);
      label = 'Enter Selling Price for discount %';
    }

    final hasHighlight = (hasBothPrices && discountRs > 0) || isOverMrp;
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: hasHighlight
            ? accentColor.withValues(alpha: 0.1)
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasHighlight ? accentColor.withValues(alpha: 0.35) : borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverMrp ? Icons.warning_amber_rounded : Icons.local_offer_outlined,
            size: 16,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a live GST, discount, SWG, and margin breakdown for a variant price.
class LivePriceCalculation extends StatelessWidget {
  final double rate;
  final double? mrp;
  final double? swg;
  final double? perUnitPrice;
  final int packQuantity;
  final double? courierCharges;
  final double gstPercentage;
  final double commissionPercentage;
  final double discountRs;
  final double discountPct;
  final bool isDark;

  const LivePriceCalculation({
    super.key,
    required this.rate,
    required this.mrp,
    required this.swg,
    this.perUnitPrice,
    this.packQuantity = 1,
    this.courierCharges,
    this.gstPercentage = 0.0,
    this.commissionPercentage = 0.0,
    required this.discountRs,
    required this.discountPct,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final commissionAmt = commissionPercentage > 0 ? (rate * commissionPercentage / 100) : null;
    final margin = (swg != null && swg! > 0) ? (rate - swg!) : null;
    final effectiveQty = packQuantity > 0 ? packQuantity : 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined, size: 15, color: Color(0xFF059669)),
              const SizedBox(width: 6),
              Text(
                'Live Price Calculation',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              if (perUnitPrice != null && perUnitPrice! > 0)
                _PriceMetric(
                  'Per Unit × Qty',
                  '₹${perUnitPrice!.toStringAsFixed(2)} × $effectiveQty',
                  isDark,
                ),
              _PriceMetric('Customer Pays', '₹${rate.toStringAsFixed(2)}', isDark, highlight: true),
              if (commissionAmt != null)
                _PriceMetric(
                  'Commission (${commissionPercentage.toStringAsFixed(1)}%)',
                  '₹${commissionAmt.toStringAsFixed(2)}',
                  isDark,
                ),
              if (courierCharges != null && courierCharges! > 0)
                _PriceMetric('Courier Charge', '₹${courierCharges!.toStringAsFixed(2)}', isDark),
              if (mrp != null && mrp! > 0 && discountRs > 0)
                _PriceMetric(
                  'Discount (${discountPct.toStringAsFixed(1)}%)',
                  '-₹${discountRs.toStringAsFixed(2)}',
                  isDark,
                  valueColor: const Color(0xFF059669),
                ),
              if (swg != null && swg! > 0) ...[
                _PriceMetric('Seller Will Get (SWG)', '₹${swg!.toStringAsFixed(2)}', isDark),
                if (margin != null)
                  _PriceMetric(
                    'Platform Margin',
                    '₹${margin.toStringAsFixed(2)}',
                    isDark,
                    valueColor: margin < 0 ? const Color(0xFFEF4444) : null,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;
  final Color? valueColor;

  const _PriceMetric(
    this.label,
    this.value,
    this.isDark, {
    this.highlight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w700,
            color: valueColor ??
                (highlight
                    ? const Color(0xFF059669)
                    : (isDark ? Colors.white : const Color(0xFF0F172A))),
          ),
        ),
      ],
    );
  }
}
