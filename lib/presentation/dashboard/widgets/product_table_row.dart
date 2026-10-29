import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seller_hub/core/models/product.dart';
import 'package:seller_hub/presentation/dashboard/widgets/product_hover_preview_thumbnail.dart';

class ProductTableRow extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final String sellerName;
  final String? sellerPhoneNumber;
  final Color categoryColor;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleSelect;
  final ValueChanged<String> onSelectSeller;
  final VoidCallback onToggleStatus;
  final VoidCallback? onToggleAvailability;
  final VoidCallback? onView;
  final VoidCallback? onDelete;
  final VoidCallback onEdit;

  const ProductTableRow({
    super.key,
    required this.product,
    required this.isSelected,
    required this.sellerName,
    this.sellerPhoneNumber,
    required this.categoryColor,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
    required this.onToggleSelect,
    required this.onSelectSeller,
    required this.onToggleStatus,
    this.onToggleAvailability,
    this.onView,
    this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? (isDark ? const Color(0xFF059669).withValues(alpha: 0.12) : const Color(0xFF059669).withValues(alpha: 0.06))
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Row Checkbox
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
              const SizedBox(width: 8),

              // 1. PRODUCT & COMPOSITION (Flex 5)
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      ProductHoverPreviewThumbnail(
                        product: product,
                        categoryColor: categoryColor,
                        size: 34,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: product.title,
                              child: Text(
                                product.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.technicalName.isNotEmpty ? product.technicalName : 'Agri Chemical Composition Unlisted',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. SKU / HSN (Flex 2)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          product.productCode,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'HSN: ${product.hsnCode}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // 3. SELLER / VENDOR (Flex 3)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => onSelectSeller(sellerName),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.storefront_rounded,
                                size: 11,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  sellerName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      InkWell(
                        onTap: (sellerPhoneNumber != null && sellerPhoneNumber!.trim().isNotEmpty)
                            ? () {
                                final phone = sellerPhoneNumber!.trim();
                                Clipboard.setData(ClipboardData(text: phone));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Copied seller phone $phone to clipboard',
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    backgroundColor: const Color(0xFF059669),
                                  ),
                                );
                              }
                            : null,
                        borderRadius: BorderRadius.circular(4),
                        child: Tooltip(
                          message: (sellerPhoneNumber != null && sellerPhoneNumber!.trim().isNotEmpty)
                              ? 'Click to copy: ${sellerPhoneNumber!.trim()}'
                              : 'No phone number available',
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (sellerPhoneNumber != null && sellerPhoneNumber!.trim().isNotEmpty) ...[
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 10,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 3),
                                ],
                                Flexible(
                                  child: SelectableText(
                                    (sellerPhoneNumber != null && sellerPhoneNumber!.trim().isNotEmpty)
                                        ? sellerPhoneNumber!.trim()
                                        : (product.sellerId.isNotEmpty
                                            ? 'ID: ${product.sellerId.length > 8 ? '${product.sellerId.substring(0, 8)}...' : product.sellerId}'
                                            : 'Default Merchant'),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: (sellerPhoneNumber != null && sellerPhoneNumber!.trim().isNotEmpty)
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                                if (sellerPhoneNumber != null && sellerPhoneNumber!.trim().isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 10,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. CATEGORY & PACK (Flex 2)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: categoryColor.withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                product.resolvedCategory,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: categoryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (product.hasMultipleVariants) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message: product.variants
                                  .map((v) => '• ${v.label} — ₹${v.displayRate.toStringAsFixed(0)} (Stock: ${v.stock})')
                                  .join('\n'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.layers_outlined, size: 9, color: Color(0xFF6366F1)),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${product.variantsCount}V',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF6366F1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.defaultVariant?.label.isNotEmpty == true
                            ? product.defaultVariant!.label
                            : '${product.packSize} ${product.unit} • ${product.variant}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // 5. PRICE / MRP (Flex 2)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.hasMultipleVariants && product.minDisplayRate != product.maxDisplayRate
                            ? product.priceRangeFormatted
                            : '₹${product.displayRate.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.hasMultipleVariants && product.minMrp != product.maxMrp
                            ? 'MRP ${product.mrpRangeFormatted}'
                            : 'MRP ₹${product.printedMrp.toStringAsFixed(0)}${product.discountPercentage > 0 ? ' • -${product.discountPercentage.toStringAsFixed(0)}%' : ''}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          decoration: product.printedMrp > product.displayRate ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // 6. STOCK LEVEL (Flex 2)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${product.totalStock} Units',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: product.totalStock > 50
                                  ? const Color(0xFF10B981)
                                  : (product.totalStock > 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.hasMultipleVariants
                                  ? '${product.variantsCount} packs in stock'
                                  : (product.totalStock > 50 ? 'In Stock' : (product.totalStock > 0 ? 'Low Stock' : 'Out of Stock')),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: product.totalStock > 50
                                    ? const Color(0xFF10B981)
                                    : (product.totalStock > 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 7. AVAILABILITY (Width 110)
              SizedBox(
                width: 110,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Tooltip(
                    message: product.isAvailable ? 'Click to mark as Unavailable' : 'Click to mark as Available',
                    child: InkWell(
                      onTap: onToggleAvailability ?? onToggleStatus,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.isAvailable
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : (isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: product.isAvailable
                                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: product.isAvailable ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                product.isAvailable ? 'Available' : 'Unavailable',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: product.isAvailable
                                      ? const Color(0xFF10B981)
                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // 8. ACTIONS (Width 88)
              SizedBox(
                width: 88,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Delete button (replaces eye icon)
                    Tooltip(
                      message: 'Delete Product',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: onDelete ?? onView,
                        child: Container(
                          width: 32,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 15,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Edit button
                    Tooltip(
                      message: 'Edit Product',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: onEdit,
                        child: Container(
                          width: 32,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFD97706).withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 15,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
