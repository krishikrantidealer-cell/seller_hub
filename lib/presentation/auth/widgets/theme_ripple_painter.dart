import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Slow, Majestic, and Elegant Theme Transition Wave Painter
/// - When entering Dark Mode: Produces an expansive Nocturnal Eclipse & Neon Mint fluid wave.
/// - When entering Light Mode: Produces a warm Solar Dawn & Golden-Emerald sunbeam bloom.
class ThemeRipplePainter extends CustomPainter {
  final double progress;
  final Offset origin;
  final Color targetColor;
  final bool isDark;
  final Color? customWaveColor;

  ThemeRipplePainter({
    required this.progress,
    required this.origin,
    required this.targetColor,
    required this.isDark,
    this.customWaveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final double maxRadius = math.sqrt(
      math.pow(math.max(origin.dx, size.width - origin.dx), 2) +
      math.pow(math.max(origin.dy, size.height - origin.dy), 2),
    );

    final currentRadius = maxRadius * progress;
    final fadeOut = (1.0 - progress).clamp(0.0, 1.0);

    if (isDark) {
      // ==========================================
      // 🌙 ENTERING DARK MODE: LOCALIZED BLACK GRADIENT WAVE BORDER
      // ==========================================
      const slateEdge = Color(0xFF334155);

      // 1. Subtle Dark Origin Spark (first 20% of transition)
      final sparkProgress = (progress / 0.20).clamp(0.0, 1.0);
      if (sparkProgress < 1.0) {
        final sparkFade = math.sin(sparkProgress * math.pi);
        final sparkPaint = Paint()
          ..color = slateEdge.withValues(alpha: (0.35 * sparkFade).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(origin, 20 * sparkProgress + 2, sparkPaint);
      }

      // 2. Localized Black Gradient Aura along Wave Border
      if (currentRadius > 6) {
        final bandWidth = (26.0 * fadeOut + 6.0);
        final auraPaint = Paint()
          ..color = Colors.black.withValues(alpha: (0.42 * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = bandWidth
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, bandWidth * 0.45);
        canvas.drawCircle(origin, currentRadius, auraPaint);
      }

      // 3. Crisp Slate-Black Wavefront Border Line
      final rimPaint = Paint()
        ..color = slateEdge.withValues(alpha: (0.65 * fadeOut * fadeOut).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.8 * fadeOut + 0.6);
      canvas.drawCircle(origin, currentRadius, rimPaint);

    } else {
      // ==========================================
      // ☀️ ENTERING LIGHT MODE: LOCALIZED WARM SUN GRADIENT WAVE BORDER
      // ==========================================
      const sunbeamEdge = Color(0xFFF59E0B);
      const sunGoldAura = Color(0xFFFBBF24);

      // 1. Subtle Warm Sun Origin Spark (first 20% of transition)
      final sparkProgress = (progress / 0.20).clamp(0.0, 1.0);
      if (sparkProgress < 1.0) {
        final sparkFade = math.sin(sparkProgress * math.pi);
        final sparkPaint = Paint()
          ..color = sunGoldAura.withValues(alpha: (0.45 * sparkFade).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(origin, 20 * sparkProgress + 2, sparkPaint);
      }

      // 2. Localized Warm Sun Color Gradient Aura along Wave Border
      if (currentRadius > 6) {
        final bandWidth = (26.0 * fadeOut + 6.0);
        final auraPaint = Paint()
          ..color = sunGoldAura.withValues(alpha: (0.35 * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = bandWidth
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, bandWidth * 0.45);
        canvas.drawCircle(origin, currentRadius, auraPaint);
      }

      // 3. Crisp Golden Sunbeam Wavefront Border Line
      final rimPaint = Paint()
        ..color = sunbeamEdge.withValues(alpha: (0.65 * fadeOut * fadeOut).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.8 * fadeOut + 0.6);
      canvas.drawCircle(origin, currentRadius, rimPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ThemeRipplePainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.origin != origin ||
           oldDelegate.isDark != isDark ||
           oldDelegate.customWaveColor != customWaveColor ||
           oldDelegate.targetColor != targetColor;
  }
}
