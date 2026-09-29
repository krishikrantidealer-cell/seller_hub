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
      // 🌙 ENTERING DARK MODE: DEEP BLACK OBSIDIAN GRADIENT SWEEP
      // ==========================================
      const pureBlack = Color(0xFF000000);
      const midnightBlack = Color(0xFF020617);
      const deepSlate = Color(0xFF0A0F1D);
      const slateEdge = Color(0xFF334155);

      // 1. Fluid Expanding Deep Black Gradient Curtain
      final washPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(normX, normY),
          radius: radRatio * 1.05,
          colors: [
            pureBlack.withValues(alpha: (0.94 * smoothFade).clamp(0.0, 1.0)),
            midnightBlack.withValues(alpha: (0.82 * smoothFade).clamp(0.0, 1.0)),
            deepSlate.withValues(alpha: (0.45 * smoothFade).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.40, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), washPaint);

      // 2. Subtle Dark Starlight Origin Bloom (first 25% of transition)
      final sparkProgress = (progress / 0.25).clamp(0.0, 1.0);
      if (sparkProgress < 1.0) {
        final sparkFade = math.sin(sparkProgress * math.pi);
        final sparkPaint = Paint()
          ..color = slateEdge.withValues(alpha: (0.40 * sparkFade).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(origin, 28 * sparkProgress + 2, sparkPaint);
      }

      // 3. Crisp, Minimalist Slate-Black Wavefront Edge
      final rimPaint = Paint()
        ..color = slateEdge.withValues(alpha: (0.60 * fadeOut * fadeOut).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.8 * fadeOut + 0.6);
      canvas.drawCircle(origin, currentRadius, rimPaint);

    } else {
      // ==========================================
      // ☀️ ENTERING LIGHT MODE: WARM SUN COLOR GRADIENT SWEEP
      // ==========================================
      const sunBeamWhite = Color(0xFFFFFBEB);
      const sunLightAmber = Color(0xFFFEF3C7);
      const solarGold = Color(0xFFFDE68A);
      const warmAmberGlow = Color(0xFFFBBF24);
      const sunbeamEdge = Color(0xFFF59E0B);

      // 1. Fluid Expanding Warm Sun Color Gradient Curtain
      final washPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(normX, normY),
          radius: radRatio * 1.05,
          colors: [
            sunBeamWhite.withValues(alpha: (0.92 * smoothFade).clamp(0.0, 1.0)),
            sunLightAmber.withValues(alpha: (0.75 * smoothFade).clamp(0.0, 1.0)),
            solarGold.withValues(alpha: (0.45 * smoothFade).clamp(0.0, 1.0)),
            warmAmberGlow.withValues(alpha: (0.18 * smoothFade).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.65, 0.88, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), washPaint);

      // 2. Warm Sun Flare Origin Bloom (first 25% of transition)
      final sparkProgress = (progress / 0.25).clamp(0.0, 1.0);
      if (sparkProgress < 1.0) {
        final sparkFade = math.sin(sparkProgress * math.pi);
        final sparkPaint = Paint()
          ..color = warmAmberGlow.withValues(alpha: (0.55 * sparkFade).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(origin, 28 * sparkProgress + 2, sparkPaint);
      }

      // 3. Crisp, Golden Sunbeam Wavefront Edge
      final rimPaint = Paint()
        ..color = sunbeamEdge.withValues(alpha: (0.55 * fadeOut * fadeOut).clamp(0.0, 1.0))
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
