import 'package:flutter/material.dart';

/// Resilient Enterprise Product Image Widget
/// Handles network loading, CORS/GCS restrictions, expired tokens, and neutral styling.
class AppProductImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final Color categoryColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final IconData fallbackIcon;
  final BoxFit fit;
  final EdgeInsetsGeometry? padding;

  const AppProductImage({
    super.key,
    required this.imageUrl,
    this.width = 40,
    this.height = 40,
    this.borderRadius = 8,
    this.categoryColor = const Color(0xFF64748B),
    this.backgroundColor,
    this.borderColor,
    this.fallbackIcon = Icons.inventory_2_outlined,
    this.fit = BoxFit.cover,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final validUrl = imageUrl.trim();
    final hasUrl = validUrl.isNotEmpty && (validUrl.startsWith('http://') || validUrl.startsWith('https://'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final neutralBorder = borderColor ?? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final defaultBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: neutralBorder,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasUrl
          ? Image.network(
              validUrl,
              width: width.isFinite ? width : double.infinity,
              height: height.isFinite ? height : double.infinity,
              fit: fit,
              filterQuality: FilterQuality.high,
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: width.isFinite ? width * 0.4 : 40,
                    height: height.isFinite ? height * 0.4 : 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildFallback(isDark);
              },
            )
          : _buildFallback(isDark),
    );
  }

  Widget _buildFallback(bool isDark) {
    return Center(
      child: Icon(
        fallbackIcon,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        size: (width < 36 ? 16 : (width < 64 ? 20 : 36)),
      ),
    );
  }
}
