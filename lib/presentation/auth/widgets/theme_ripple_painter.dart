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
    // Smooth bell curve for ambient aura
    final smoothFade = math.sin(progress * math.pi);

    final normX = (size.width > 0 ? (origin.dx / size.width) * 2 - 1 : 0.0).clamp(-1.0, 1.0);
    final normY = (size.height > 0 ? (origin.dy / size.height) * 2 - 1 : 0.0).clamp(-1.0, 1.0);
    final double maxDim = math.max(size.width, size.height);
    final radRatio = (currentRadius / (maxDim > 0 ? maxDim : 1)).clamp(0.01, 2.2);

    if (isDark) {
      // ==========================================
      // 🌙 ENTERING DARK MODE: MINIMALIST NOCTURNAL SLATE SWEEP
      // Professional, clean monochromatic shadow curtain with refined slate rim
      // ==========================================
      const darkBackdrop = Color(0xFF0A0F1D);
      const deepMidnight = Color(0xFF020617);
      const slateEdge = Color(0xFF475569);

      // 1. Fluid Expanding Deep Slate Shadow Curtain
      final washPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(normX, normY),
          radius: radRatio * 1.05,
          colors: [
            darkBackdrop.withValues(alpha: (0.85 * smoothFade).clamp(0.0, 1.0)),
            deepMidnight.withValues(alpha: (0.65 * smoothFade).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.70, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), washPaint);

      // 2. Subtle Monochrome Origin Bloom (first 25% of transition)
      final sparkProgress = (progress / 0.25).clamp(0.0, 1.0);
      if (sparkProgress < 1.0) {
        final sparkFade = math.sin(sparkProgress * math.pi);
        final sparkPaint = Paint()
          ..color = const Color(0xFF94A3B8).withValues(alpha: (0.35 * sparkFade).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(origin, 28 * sparkProgress + 2, sparkPaint);
      }

      // 3. Crisp, Minimalist Slate Wavefront Edge
      final rimPaint = Paint()
        ..color = slateEdge.withValues(alpha: (0.50 * fadeOut * fadeOut).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.8 * fadeOut + 0.6);
      canvas.drawCircle(origin, currentRadius, rimPaint);

    } else {
      // ==========================================
      // ☀️ ENTERING LIGHT MODE: CRISP ALABASTER DAYLIGHT SWEEP
      // Professional, clean alabaster daylight curtain with refined silver rim
      // ==========================================
      const lightBackdrop = Color(0xFFF8FAFC);
      const softSlate = Color(0xFFF1F5F9);
      const silverEdge = Color(0xFFCBD5E1);

      // 1. Fluid Expanding Crisp Alabaster Curtain
      final washPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(normX, normY),
          radius: radRatio * 1.05,
          colors: [
            lightBackdrop.withValues(alpha: (0.85 * smoothFade).clamp(0.0, 1.0)),
            softSlate.withValues(alpha: (0.60 * smoothFade).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.70, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), washPaint);

      // 2. Subtle Monochrome Origin Bloom (first 25% of transition)
      final sparkProgress = (progress / 0.25).clamp(0.0, 1.0);
      if (sparkProgress < 1.0) {
        final sparkFade = math.sin(sparkProgress * math.pi);
        final sparkPaint = Paint()
          ..color = Colors.white.withValues(alpha: (0.50 * sparkFade).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(origin, 28 * sparkProgress + 2, sparkPaint);
      }

      // 3. Crisp, Minimalist Silver Wavefront Edge
      final rimPaint = Paint()
        ..color = silverEdge.withValues(alpha: (0.60 * fadeOut * fadeOut).clamp(0.0, 1.0))
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
