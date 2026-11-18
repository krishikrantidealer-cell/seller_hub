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
  static const double fixedCodAndBankCharge = 60.0;

  static const List<(int, double)> _weightCourierSlabs = [
    (100, 82.13),
    (400, 135.23),
    (700, 145.0),
    (900, 165.0),
    (1100, 190.0),
    (1200, 172.32),
    (1300, 176.78),
    (1400, 181.24),
    (1500, 185.7),
    (1600, 190.17),
    (1700, 194.63),
    (1800, 199.09),
    (1900, 203.55),
    (2000, 208.01),
    (2100, 212.31),
    (2200, 216.62),
    (2300, 220.92),
    (2400, 225.23),
    (2500, 229.53),
    (2600, 233.83),
    (2700, 238.14),
    (2800, 242.44),
    (2900, 246.75),
    (4000, 251.05),
    (4100, 266.63),
    (4200, 282.2),
    (4300, 297.78),
    (4400, 313.35),
    (4500, 328.93),
    (4600, 344.51),
    (4700, 360.08),
    (4800, 375.66),
    (4900, 391.23),
    (5000, 406.81),
    (5100, 408.65),
    (5200, 410.5),
    (5300, 412.34),
    (5400, 414.19),
    (5500, 416.03),
    (5600, 417.87),
    (5700, 419.72),
    (5800, 421.56),
    (5900, 423.4),
    (6000, 425.25),
    (6100, 427.09),
    (6200, 428.94),
    (6300, 430.78),
    (6400, 432.62),
    (6500, 434.47),
    (6600, 436.31),
    (6700, 438.15),
    (6800, 440.0),
    (6900, 441.84),
    (7000, 443.69),
    (7100, 445.53),
    (7200, 447.37),
    (7300, 449.22),
    (7400, 451.06),
    (7500, 452.9),
    (7600, 454.75),
    (7700, 456.59),
    (7800, 458.44),
    (7900, 460.28),
    (8000, 462.12),
    (8100, 463.97),
    (8200, 465.81),
    (8300, 467.66),
    (8400, 469.5),
    (11000, 499.0),
    (13900, 567.0),
    (14900, 600.18),
    (15900, 612.92),
    (16900, 674.88),
    (17900, 702.84),
    (20000, 758.76),
  ];

  static double computeCourierChargeFromWeightGrams(double weightGrams) {
    if (weightGrams <= 0) return 0.0;
    for (final slab in _weightCourierSlabs) {
      if (weightGrams <= slab.$1) return slab.$2;
    }
    return _weightCourierSlabs.last.$2;
  }

  static double computeSellingRate({
    required double swg,
    required double commissionPercentage,
    required double courierCharges,
    double codCharge = fixedCodAndBankCharge,
    bool isMarketplace = true,
  }) {
    if (swg <= 0) return 0.0;
    if (!isMarketplace) {
      return swg + (swg * commissionPercentage / 100.0);
    }
    final factor = 1.0 - (commissionPercentage / 100.0);
    if (factor <= 0) return 0.0;
    return (swg + courierCharges + codCharge) / factor;
  }

  static double computeSwgFromSellingRate({
    required double sellingRate,
    required double commissionPercentage,
  }) {
    if (sellingRate <= 0) return 0.0;
    return (sellingRate * (1.0 - (commissionPercentage / 100.0))).clamp(0.0, double.infinity);
  }

  final double rate;
  final double? mrp;
  final double? swg;
  final int packQuantity;
  final double? courierCharges;
  final double gstPercentage;
  final double commissionPercentage;
  final double discountRs;
  final double discountPct;
  final bool isDark;
  final bool isMarketplace;

  const LivePriceCalculation({
    super.key,
    required this.rate,
    required this.mrp,
    required this.swg,
    this.packQuantity = 1,
    this.courierCharges,
    this.gstPercentage = 0.0,
    this.commissionPercentage = 0.0,
    required this.discountRs,
    required this.discountPct,
    required this.isDark,
    this.isMarketplace = true,
  });

  @override
  Widget build(BuildContext context) {
    final commissionAmt = commissionPercentage > 0 ? (rate * commissionPercentage / 100) : null;
    final margin = (swg != null && swg! > 0) ? (rate - swg!) : null;

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
              _PriceMetric('Customer Pays', '₹${rate.toStringAsFixed(2)}', isDark, highlight: true),
              if (commissionAmt != null)
                _PriceMetric(
                  'Commission (${commissionPercentage.toStringAsFixed(1)}%)',
                  '₹${commissionAmt.toStringAsFixed(2)}',
                  isDark,
                ),
              if (isMarketplace && courierCharges != null && courierCharges! > 0)
                _PriceMetric('Courier Charge', '₹${courierCharges!.toStringAsFixed(2)}', isDark),
              if (isMarketplace)
                _PriceMetric(
                  'COD & Bank Charge',
                  '₹${fixedCodAndBankCharge.toStringAsFixed(2)}',
                  isDark,
                ),
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

/// Clean card toggle for Live / Available for Orders state.
class ProductListingStatusToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isDark;

  const ProductListingStatusToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF059669);
    final bgColor = value
        ? activeColor.withValues(alpha: isDark ? 0.14 : 0.06)
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
    final borderColor = value
        ? activeColor.withValues(alpha: 0.45)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: value
                      ? activeColor.withValues(alpha: 0.16)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  value ? Icons.visibility_rounded : Icons.visibility_off_outlined,
                  size: 18,
                  color: value ? activeColor : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Live / Available for Orders',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: value
                                ? activeColor.withValues(alpha: 0.16)
                                : const Color(0xFF64748B).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            value ? 'LIVE' : 'DRAFT',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: value ? activeColor : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value
                          ? 'Visible on storefront and open for customer orders'
                          : 'Hidden from storefront until published live',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: value,
                activeTrackColor: activeColor,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Professional segmented pill toggle for Marketplace vs Dealer-Based Commission.
class PricingModeToggle extends StatelessWidget {
  final bool isMarketplace;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const PricingModeToggle({
    super.key,
    required this.isMarketplace,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final trackBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withValues(alpha: 0.65);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Pricing Model',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isMarketplace
                      ? 'Courier & ₹60 COD/bank charges included'
                      : 'SWG = Selling Rate − Commission % (no courier/COD)',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: trackBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PricingSegmentButton(
                    label: 'Marketplace',
                    icon: Icons.storefront_rounded,
                    selected: isMarketplace,
                    isDark: isDark,
                    onTap: () {
                      if (!isMarketplace) onChanged(true);
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _PricingSegmentButton(
                    label: 'Dealer Commission',
                    icon: Icons.handshake_outlined,
                    selected: !isMarketplace,
                    isDark: isDark,
                    onTap: () {
                      if (isMarketplace) onChanged(false);
                    },
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

class _PricingSegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _PricingSegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF059669);
    final selectedBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(color: activeColor.withValues(alpha: 0.45), width: 1.1)
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? activeColor
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
