import 'package:flutter/material.dart';

/// Resilient Enterprise Product Image Widget
/// Handles network loading, CORS/GCS restrictions, candidate fallback URLs, and expiration resilience.
class AppProductImage extends StatefulWidget {
  final String imageUrl;
  final List<String> fallbackUrls;
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
    this.fallbackUrls = const [],
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
  State<AppProductImage> createState() => _AppProductImageState();
}

class _AppProductImageState extends State<AppProductImage> {
  int _candidateIndex = 0;
  List<String> _candidates = [];

  @override
  void initState() {
    super.initState();
    _recomputeCandidates();
  }

  @override
  void didUpdateWidget(covariant AppProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.fallbackUrls != widget.fallbackUrls) {
      _recomputeCandidates();
    }
  }

  void _recomputeCandidates() {
    final list = <String>[];
    final primary = widget.imageUrl.trim();
    if (primary.isNotEmpty && (primary.startsWith('http://') || primary.startsWith('https://'))) {
      list.add(primary);
    }
    for (final fb in widget.fallbackUrls) {
      final trimmed = fb.trim();
      if (trimmed.isNotEmpty &&
          (trimmed.startsWith('http://') || trimmed.startsWith('https://')) &&
          !list.contains(trimmed)) {
        list.add(trimmed);
      }
    }
    _candidates = list;
    _candidateIndex = 0;
  }

  String? get _currentUrl {
    if (_candidates.isEmpty || _candidateIndex >= _candidates.length) return null;
    return _candidates[_candidateIndex];
  }

  void _onImageError() {
    if (_candidateIndex + 1 < _candidates.length) {
      if (mounted) {
        setState(() {
          _candidateIndex++;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final neutralBorder = widget.borderColor ?? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final defaultBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final activeUrl = _currentUrl;

    return Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: neutralBorder,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: activeUrl != null
          ? Image.network(
              activeUrl,
              key: ValueKey(activeUrl),
              width: widget.width.isFinite ? widget.width : double.infinity,
              height: widget.height.isFinite ? widget.height : double.infinity,
              fit: widget.fit,
              filterQuality: FilterQuality.high,
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                // If small thumbnail (like in catalog table), show clean placeholder instead of tiny spinner
                if (widget.width < 45 || widget.height < 45) {
                  return Container(
                    color: widget.backgroundColor ?? defaultBg,
                    alignment: Alignment.center,
                    child: Icon(
                      widget.fallbackIcon,
                      size: (widget.width < 36 ? 16 : 20),
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    ),
                  );
                }
                return Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // If there's another candidate URL, try it automatically
                if (_candidateIndex + 1 < _candidates.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _onImageError());
                }
                return _buildFallback(isDark);
              },
            )
          : _buildFallback(isDark),
    );
  }

  Widget _buildFallback(bool isDark) {
    return Center(
      child: Icon(
        widget.fallbackIcon,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        size: (widget.width < 36 ? 16 : (widget.width < 64 ? 20 : 36)),
      ),
    );
  }
}
