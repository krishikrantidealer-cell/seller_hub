import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Distinct Radiant Theme Transition Wave Painter
/// - When entering Dark Mode: Produces a high-tech Nocturnal Eclipse & Neon Mint shockwave.
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
    final smoothFade = math.sin(progress * math.pi);

    final normX = (size.width > 0 ? (origin.dx / size.width) * 2 - 1 : 0.0).clamp(-1.0, 1.0);
    final normY = (size.height > 0 ? (origin.dy / size.height) * 2 - 1 : 0.0).clamp(-1.0, 1.0);
    final double maxDim = math.max(size.width, size.height);
    final radRatio = (currentRadius / (maxDim > 0 ? maxDim : 1)).clamp(0.01, 2.0);

    if (isDark) {
      // ==========================================
      // 🌙 ENTERING DARK MODE: NOCTURNAL ECLIPSE & NEON MINT
      // ==========================================
      final primaryMint = customWaveColor ?? const Color(0xFF10B981);
      final neonCyan = const Color(0xFF34D399);

      // 1. Electric Origin Starburst Flash (first 25%)
      final sparkProgress = (progress / 0.25).clamp(0.0, 1.0);
      if (sparkProgress < 1.0) {
        final sparkFade = 1.0 - sparkProgress;
        final sparkPaint = Paint()
          ..color = neonCyan.withValues(alpha: (0.55 * sparkFade).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(origin, 32 * sparkProgress + 4, sparkPaint);
      }

      // 2. Deep Cosmic Aura
      if (smoothFade > 0.01) {
        final glowPaint = Paint()
          ..shader = RadialGradient(
            center: Alignment(normX, normY),
            radius: radRatio * 1.1,
            colors: [
              neonCyan.withValues(alpha: (0.18 * smoothFade).clamp(0.0, 1.0)),
              primaryMint.withValues(alpha: (0.06 * smoothFade).clamp(0.0, 1.0)),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
      }

      // 3. Outer Harmonic Cyber-Ripple Ring
      if (currentRadius > 15) {
        final outerRingPaint = Paint()
          ..color = primaryMint.withValues(alpha: (0.35 * fadeOut * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(origin, (currentRadius + 14).clamp(0.0, double.infinity), outerRingPaint);
      }

      // 4. Primary Neon Shockwave Crest
      final primaryWavePaint = Paint()
        ..color = neonCyan.withValues(alpha: (0.90 * fadeOut * fadeOut).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (4.2 * fadeOut + 0.9);
      canvas.drawCircle(origin, currentRadius, primaryWavePaint);

      // 5. Inner Trailing Resonance Ring
      if (currentRadius > 35) {
        final secondaryWavePaint = Paint()
          ..color = const Color(0xFF059669).withValues(alpha: (0.50 * fadeOut * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2.2 * fadeOut + 0.5);
        canvas.drawCircle(origin, (currentRadius - 28).clamp(0.0, double.infinity), secondaryWavePaint);
      }
    } else {
      // ==========================================
      // ☀️ ENTERING LIGHT MODE: SOLAR DAWN & GOLDEN EMERALD
      // ==========================================
      const solarGold = Color(0xFFF59E0B);
      const amberGlow = Color(0xFFFBBF24);
      const freshEmerald = Color(0xFF10B981);

      // 1. Warm Solar Flare Burst Flash (first 28%)
      final sparkProgress = (progress / 0.28).clamp(0.0, 1.0);
      if (sparkProgress < 1.0) {
        final sparkFade = 1.0 - sparkProgress;
        final sparkPaint = Paint()
          ..color = amberGlow.withValues(alpha: (0.65 * sparkFade).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(origin, 36 * sparkProgress + 5, sparkPaint);
      }

      // 2. Radiant Morning Sunbeam Aura
      if (smoothFade > 0.01) {
        final sunbeamPaint = Paint()
          ..shader = RadialGradient(
            center: Alignment(normX, normY),
            radius: radRatio * 1.25,
            colors: [
              amberGlow.withValues(alpha: (0.22 * smoothFade).clamp(0.0, 1.0)),
              freshEmerald.withValues(alpha: (0.08 * smoothFade).clamp(0.0, 1.0)),
              Colors.transparent,
            ],
            stops: const [0.0, 0.65, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), sunbeamPaint);
      }

      // 3. Golden Sunbeam Leading Ring
      if (currentRadius > 12) {
        final leadingRingPaint = Paint()
          ..color = amberGlow.withValues(alpha: (0.45 * fadeOut * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(origin, (currentRadius + 16).clamp(0.0, double.infinity), leadingRingPaint);
      }

      // 4. Primary Golden-Emerald Wavefront Crest
      final primaryWavePaint = Paint()
        ..color = solarGold.withValues(alpha: (0.85 * fadeOut * fadeOut).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (4.5 * fadeOut + 1.0);
      canvas.drawCircle(origin, currentRadius, primaryWavePaint);

      // 5. Inner Fresh Emerald Daybreak Wave
      if (currentRadius > 30) {
        final innerDaybreakPaint = Paint()
          ..color = freshEmerald.withValues(alpha: (0.60 * fadeOut * fadeOut).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2.5 * fadeOut + 0.6);
        canvas.drawCircle(origin, (currentRadius - 24).clamp(0.0, double.infinity), innerDaybreakPaint);
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
