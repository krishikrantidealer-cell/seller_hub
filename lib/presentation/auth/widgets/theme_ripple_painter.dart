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
      // 🌙 ENTERING DARK MODE: NOCTURNAL ECLIPSE & LUNAR OBSIDIAN
      // Deep space midnight curtain with celestial moonlight & twilight emerald
      // ==========================================
      const midnightObsidian = Color(0xFF020617);
      const deepNightSky = Color(0xFF0A0F1D);
      const twilightSlate = Color(0xFF1E293B);
      const lunarSilver = Color(0xFFCBD5E1);
      const celestialBlue = Color(0xFF60A5FA);
      const deepNocturnalEmerald = Color(0xFF064E3B);

      // 1. Fluid Expanding Deep Midnight Blanket Veil (True darkness sweep)
      final washPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(normX, normY),
          radius: radRatio * 1.05,
          colors: [
            midnightObsidian.withValues(alpha: (0.78 * smoothFade).clamp(0.0, 1.0)),
            deepNightSky.withValues(alpha: (0.58 * smoothFade).clamp(0.0, 1.0)),
            twilightSlate.withValues(alpha: (0.28 * smoothFade).clamp(0.0, 1.0)),
            deepNocturnalEmerald.withValues(alpha: (0.15 * smoothFade).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 0.75, 0.90, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), washPaint);

      // 2. Celestial Lunar Starburst Spark at Origin (first 30% of transition)
      final sparkProgress = (progress / 0.30).clamp(0.0, 1.0);
      if (sparkProgress < 1.0) {
        final sparkFade = math.sin(sparkProgress * math.pi);
        // Cool lunar moon-flare
        final sparkPaint = Paint()
          ..color = lunarSilver.withValues(alpha: (0.75 * sparkFade).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(origin, 36 * sparkProgress + 3, sparkPaint);

        // Soft celestial halo
        final haloPaint = Paint()
          ..color = celestialBlue.withValues(alpha: (0.40 * sparkFade).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(origin, 60 * sparkProgress + 6, haloPaint);
      }

      // 3. Expanding Twilight Obsidian Aura
      if (smoothFade > 0.01) {
        final auraPaint = Paint()
          ..shader = RadialGradient(
            center: Alignment(normX, normY),
            radius: radRatio * 1.20,
            colors: [
              midnightObsidian.withValues(alpha: (0.45 * smoothFade).clamp(0.0, 1.0)),
              twilightSlate.withValues(alpha: (0.25 * smoothFade).clamp(0.0, 1.0)),
              celestialBlue.withValues(alpha: (0.10 * smoothFade).clamp(0.0, 1.0)),
              Colors.transparent,
            ],
            stops: const [0.0, 0.50, 0.80, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), auraPaint);
      }

      // 4. Lunar Silver Leading Edge Ring (Fine moonlight crest)
      if (currentRadius > 14) {
        final lunarRimPaint = Paint()
          ..color = lunarSilver.withValues(alpha: (0.65 * fadeOut * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2.2 * fadeOut + 0.8);
        canvas.drawCircle(origin, currentRadius, lunarRimPaint);
      }

      // 5. Deep Midnight Shadow Shockwave (Expands just behind the lunar rim)
      if (currentRadius > 10) {
        final shadowWavePaint = Paint()
          ..color = midnightObsidian.withValues(alpha: (0.85 * fadeOut * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = (5.5 * fadeOut + 1.5);
        canvas.drawCircle(origin, (currentRadius - 8).clamp(0.0, double.infinity), shadowWavePaint);
      }

      // 6. Secondary Twilight Indigo Resonance Ring
      if (currentRadius > 32) {
        final twilightWavePaint = Paint()
          ..color = celestialBlue.withValues(alpha: (0.35 * fadeOut * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2.0 * fadeOut + 0.5);
        canvas.drawCircle(origin, (currentRadius - 28).clamp(0.0, double.infinity), twilightWavePaint);
      }

      // 7. Tertiary Deep Nocturnal Emerald Horizon Echo
      if (currentRadius > 65) {
        final emeraldEchoPaint = Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: (0.22 * fadeOut * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.4 * fadeOut + 0.3);
        canvas.drawCircle(origin, (currentRadius - 56).clamp(0.0, double.infinity), emeraldEchoPaint);
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
