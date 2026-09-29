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
      // 🌙 ENTERING DARK MODE: NOCTURNAL ECLIPSE & NEON MINT
      // ==========================================
      final primaryMint = customWaveColor ?? const Color(0xFF10B981);
      const neonCyan = Color(0xFF34D399);

      // 1. Fluid Expanding Background Wash Veil
      final washPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(normX, normY),
          radius: radRatio,
          colors: [
            const Color(0xFF0A0F1D).withValues(alpha: (0.35 * smoothFade).clamp(0.0, 1.0)),
            primaryMint.withValues(alpha: (0.12 * smoothFade).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), washPaint);

      // 2. Slow Blooming Origin Starburst Spark (first 35% of animation)
      final sparkProgress = (progress / 0.35).clamp(0.0, 1.0);
      if (sparkProgress < 1.0) {
        final sparkFade = math.sin(sparkProgress * math.pi);
        final sparkPaint = Paint()
          ..color = neonCyan.withValues(alpha: (0.60 * sparkFade).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(origin, 42 * sparkProgress + 4, sparkPaint);
      }

      // 3. Expanding Soft Radiant Aura
      if (smoothFade > 0.01) {
        final glowPaint = Paint()
          ..shader = RadialGradient(
            center: Alignment(normX, normY),
            radius: radRatio * 1.15,
            colors: [
              neonCyan.withValues(alpha: (0.22 * smoothFade).clamp(0.0, 1.0)),
              primaryMint.withValues(alpha: (0.08 * smoothFade).clamp(0.0, 1.0)),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
      }

      // 4. Outer Harmonic Resonance Ring
      if (currentRadius > 15) {
        final outerRingPaint = Paint()
          ..color = primaryMint.withValues(alpha: (0.38 * fadeOut * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        canvas.drawCircle(origin, (currentRadius + 22).clamp(0.0, double.infinity), outerRingPaint);
      }

      // 5. Primary Neon Wavefront Crest (Majestic slow pulse)
      final primaryWavePaint = Paint()
        ..color = neonCyan.withValues(alpha: (0.88 * fadeOut * fadeOut).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (4.8 * fadeOut + 1.2);
      canvas.drawCircle(origin, currentRadius, primaryWavePaint);

      // 6. Secondary Inner Trailing Resonance Ring
      if (currentRadius > 35) {
        final secondaryWavePaint = Paint()
          ..color = const Color(0xFF059669).withValues(alpha: (0.52 * fadeOut * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2.6 * fadeOut + 0.6);
        canvas.drawCircle(origin, (currentRadius - 32).clamp(0.0, double.infinity), secondaryWavePaint);
      }

      // 7. Tertiary Deep Tail Echo Ring
      if (currentRadius > 70) {
        final tertiaryWavePaint = Paint()
          ..color = const Color(0xFF047857).withValues(alpha: (0.28 * fadeOut * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.5 * fadeOut + 0.4);
        canvas.drawCircle(origin, (currentRadius - 64).clamp(0.0, double.infinity), tertiaryWavePaint);
      }
    } else {
      // ==========================================
      // ☀️ ENTERING LIGHT MODE: SOLAR DAWN & GOLDEN EMERALD
      // ==========================================
      const solarGold = Color(0xFFF59E0B);
      const amberGlow = Color(0xFFFBBF24);
      const freshEmerald = Color(0xFF10B981);

      // 1. Fluid Expanding Daylight Wash Veil
      final washPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(normX, normY),
          radius: radRatio,
          colors: [
            const Color(0xFFF8FAFC).withValues(alpha: (0.40 * smoothFade).clamp(0.0, 1.0)),
            amberGlow.withValues(alpha: (0.15 * smoothFade).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), washPaint);

      // 2. Slow Warm Solar Flare Burst Flash (first 35% of animation)
      final sparkProgress = (progress / 0.35).clamp(0.0, 1.0);
      if (sparkProgress < 1.0) {
        final sparkFade = math.sin(sparkProgress * math.pi);
        final sparkPaint = Paint()
          ..color = amberGlow.withValues(alpha: (0.68 * sparkFade).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(origin, 46 * sparkProgress + 5, sparkPaint);
      }

      // 3. Radiant Morning Sunbeam Aura
      if (smoothFade > 0.01) {
        final sunbeamPaint = Paint()
          ..shader = RadialGradient(
            center: Alignment(normX, normY),
            radius: radRatio * 1.25,
            colors: [
              amberGlow.withValues(alpha: (0.26 * smoothFade).clamp(0.0, 1.0)),
              freshEmerald.withValues(alpha: (0.10 * smoothFade).clamp(0.0, 1.0)),
              Colors.transparent,
            ],
            stops: const [0.0, 0.65, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), sunbeamPaint);
      }

      // 4. Golden Sunbeam Leading Outer Ring
      if (currentRadius > 12) {
        final leadingRingPaint = Paint()
          ..color = amberGlow.withValues(alpha: (0.48 * fadeOut * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        canvas.drawCircle(origin, (currentRadius + 24).clamp(0.0, double.infinity), leadingRingPaint);
      }

      // 5. Primary Golden-Emerald Wavefront Crest
      final primaryWavePaint = Paint()
        ..color = solarGold.withValues(alpha: (0.88 * fadeOut * fadeOut).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (5.0 * fadeOut + 1.2);
      canvas.drawCircle(origin, currentRadius, primaryWavePaint);

      // 6. Secondary Inner Fresh Emerald Daybreak Wave
      if (currentRadius > 30) {
        final innerDaybreakPaint = Paint()
          ..color = freshEmerald.withValues(alpha: (0.64 * fadeOut * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2.8 * fadeOut + 0.7);
        canvas.drawCircle(origin, (currentRadius - 28).clamp(0.0, double.infinity), innerDaybreakPaint);
      }

      // 7. Tertiary Soft Morning Dawn Echo Ring
      if (currentRadius > 65) {
        final tertiaryDawnPaint = Paint()
          ..color = const Color(0xFF6EE7B7).withValues(alpha: (0.32 * fadeOut * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.6 * fadeOut + 0.4);
        canvas.drawCircle(origin, (currentRadius - 58).clamp(0.0, double.infinity), tertiaryDawnPaint);
      }
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
