import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders HTML content (headings, paragraphs, bold tags, unordered/ordered lists)
/// with typography and dark/light mode themes tailored for enterprise dashboard views.
/// Supports a collapsible 4-line clamped view with a "more..." / "less..." expander button.
class AppHtmlView extends StatefulWidget {
  final String htmlData;
  final TextStyle? style;
  final double fontSize;
  final double lineHeight;
  final Color? color;
  final Color? boldColor;
  final bool collapsible;
  final int maxLines;

  const AppHtmlView({
    super.key,
    required this.htmlData,
    this.style,
    this.fontSize = 13.5,
    this.lineHeight = 1.55,
    this.color,
    this.boldColor,
    this.collapsible = false,
    this.maxLines = 4,
  });

  @override
  State<AppHtmlView> createState() => _AppHtmlViewState();
}

class _AppHtmlViewState extends State<AppHtmlView> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.htmlData.trim();
    if (trimmed.isEmpty) {
      return Text(
        'No detailed description provided.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: widget.fontSize,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF64748B)
              : const Color(0xFF94A3B8),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = widget.color ?? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155));
    final headingColorHex = isDark ? '#FFFFFF' : '#0F172A';
    final boldColorHex = widget.boldColor != null
        ? '#${widget.boldColor!.toARGB32().toRadixString(16).substring(2)}'
        : (isDark ? '#FFFFFF' : '#0F172A');
    final accentGreenHex = '#059669';
    final surfaceBg = isDark ? const Color(0xFF161E2E) : Colors.white;

    final htmlContent = HtmlWidget(
      trimmed,
      textStyle: widget.style ??
          GoogleFonts.plusJakartaSans(
            fontSize: widget.fontSize,
            height: widget.lineHeight,
            color: defaultTextColor,
          ),
      customStylesBuilder: (element) {
        switch (element.localName) {
          case 'h1':
          case 'h2':
          case 'h3':
          case 'h4':
            return {
              'color': headingColorHex,
              'font-weight': '700',
              'margin-top': '8px',
              'margin-bottom': '4px',
            };
          case 'strong':
          case 'b':
            return {
              'color': boldColorHex,
              'font-weight': '700',
            };
          case 'p':
            return {
              'margin-bottom': '6px',
            };
          case 'ul':
          case 'ol':
            return {
              'padding-left': '18px',
              'margin-top': '4px',
              'margin-bottom': '8px',
            };
          case 'li':
            return {
              'margin-bottom': '3px',
            };
          case 'a':
            return {
              'color': accentGreenHex,
              'text-decoration': 'none',
              'font-weight': '600',
            };
          default:
            return null;
        }
      },
    );

    if (!widget.collapsible) {
      return htmlContent;
    }

    // 4-line height constraint
    final collapsedHeight = (widget.fontSize * widget.lineHeight * widget.maxLines) + 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? htmlContent
              : Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: collapsedHeight),
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          maxHeight: double.infinity,
                          child: htmlContent,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 38,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              surfaceBg.withValues(alpha: 0.0),
                              surfaceBg.withValues(alpha: 0.95),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isExpanded ? 'less...' : 'more...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: const Color(0xFF059669),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
