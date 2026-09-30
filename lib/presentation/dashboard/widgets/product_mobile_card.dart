import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/models/product.dart';

class ProductMobileCard extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final String sellerName;
  final Color categoryColor;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleSelect;
  final ValueChanged<String> onSelectSeller;
  final VoidCallback onView;
  final VoidCallback onEdit;

  const ProductMobileCard({
    super.key,
    required this.product,
    required this.isSelected,
    required this.sellerName,
    required this.categoryColor,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
    required this.onToggleSelect,
    required this.onSelectSeller,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected
            ? (isDark ? const Color(0xFF059669).withValues(alpha: 0.12) : const Color(0xFF059669).withValues(alpha: 0.06))
            : Colors.transparent,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Image + Title + Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Checkbox(
                    value: isSelected,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeColor: const Color(0xFF059669),
                    onChanged: (val) => onToggleSelect(val ?? false),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: categoryColor.withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Icon(Icons.inventory_2_outlined, color: categoryColor, size: 16),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.technicalName.isNotEmpty ? product.technicalName : 'Agri Chemical Spec Unlisted',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${product.displayRate.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF059669),
                      ),
                    ),
                    Text(
                      'MRP ₹${product.printedMrp.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        decoration: product.printedMrp > product.displayRate ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: Badges (Code, Category, Vendor, Pack)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.productCode,
                    style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: categoryColor.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    product.category,
                    style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, color: categoryColor),
                  ),
                ),
                InkWell(
                  onTap: () => onSelectSeller(sellerName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront_rounded, size: 10, color: Color(0xFF2563EB)),
                        const SizedBox(width: 3),
                        Text(
                          sellerName,
                          style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  '${product.packSize} ${product.unit} • ${product.variant}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 3: Stock status & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: product.stock > 50 ? const Color(0xFF10B981) : (product.stock > 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product.stock} units • ${product.stock > 50 ? 'In Stock' : (product.stock > 0 ? 'Low Stock' : 'Out of Stock')}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: product.stock > 50 ? const Color(0xFF10B981) : (product.stock > 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.visibility_outlined, size: 12),
                      label: Text('View', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 12),
                      label: Text('Edit', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
