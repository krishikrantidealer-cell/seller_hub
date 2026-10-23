import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/product.dart';
import 'app_product_image.dart';

/// Amazon/ERP-style hover thumbnail widget for catalog tables
/// Displays a high-resolution, full-aspect ratio floating preview when hovered.
class ProductHoverPreviewThumbnail extends StatefulWidget {
  final Product product;
  final Color categoryColor;
  final double size;

  const ProductHoverPreviewThumbnail({
    super.key,
    required this.product,
    required this.categoryColor,
    this.size = 34,
  });

  @override
  State<ProductHoverPreviewThumbnail> createState() => _ProductHoverPreviewThumbnailState();
}

class _ProductHoverPreviewThumbnailState extends State<ProductHoverPreviewThumbnail> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _showOverlay() {
    _hideOverlay();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pick highest available resolution image for preview
    String highResUrl = '';
    if (widget.product.productImages.isNotEmpty) {
      final pi = widget.product.productImages.first;
      if (pi.originalUrl.isNotEmpty) {
        highResUrl = pi.originalUrl;
      } else if (pi.midUrl.isNotEmpty) {
        highResUrl = pi.midUrl;
      } else if (pi.lowUrl.isNotEmpty) {
        highResUrl = pi.lowUrl;
      }
    }
    if (highResUrl.isEmpty) {
      highResUrl = widget.product.primaryImageUrl.isNotEmpty
          ? widget.product.primaryImageUrl
          : widget.product.thumbnailUrl;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 260,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(42, -50),
            child: Material(
              color: Colors.transparent,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // High-Res Image filled in width and height
                      SizedBox(
                        height: 250,
                        width: double.infinity,
                        child: AppProductImage(
                          imageUrl: highResUrl,
                          width: double.infinity,
                          height: 250,
                          borderRadius: 0,
                          borderColor: Colors.transparent,
                          categoryColor: widget.categoryColor,
                          fit: BoxFit.cover,
                          padding: EdgeInsets.zero,
                          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        ),
                      ),
                      // Info Bar below image
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.product.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.product.productCode,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.product.priceRangeFormatted,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
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
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _showOverlay(),
        onExit: (_) => _hideOverlay(),
        cursor: SystemMouseCursors.click,
        child: AppProductImage(
          imageUrl: widget.product.thumbnailUrl,
          width: widget.size,
          height: widget.size,
          categoryColor: widget.categoryColor,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
