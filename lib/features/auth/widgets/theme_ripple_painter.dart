import 'dart:math' as math;
import 'package:flutter/material.dart';

class ThemeRipplePainter extends CustomPainter {
  final double progress;
  final Offset origin;
  final Color targetColor;
  final Color waveColor;
  final bool isDark;

  ThemeRipplePainter({
    required this.progress,
    required this.origin,
    required this.targetColor,
    required this.waveColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    // Calculate maximum radius to cover the entire screen from the origin
    final double maxRadius = math.sqrt(
      math.pow(math.max(origin.dx, size.width - origin.dx), 2) +
      math.pow(math.max(origin.dy, size.height - origin.dy), 2),
    );

    final currentRadius = maxRadius * progress;
    final fadeOut = (1.0 - progress).clamp(0.0, 1.0);
    final smoothFade = math.sin(progress * math.pi);

    // 1. Initial Spark Flash at Origin
    final sparkProgress = (progress / 0.22).clamp(0.0, 1.0);
    if (sparkProgress < 1.0) {
      final sparkFade = 1.0 - sparkProgress;
      final sparkPaint = Paint()
        ..color = waveColor.withValues(alpha: (0.55 * sparkFade).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(origin, 32 * sparkProgress + 4, sparkPaint);
    }

    // 2. Radiant Expanding Aura Glow
    if (smoothFade > 0.01) {
      final normX = (size.width > 0 ? (origin.dx / size.width) * 2 - 1 : 0.0).clamp(-1.0, 1.0);
      final normY = (size.height > 0 ? (origin.dy / size.height) * 2 - 1 : 0.0).clamp(-1.0, 1.0);
      final double maxDim = math.max(size.width, size.height);
      final radRatio = (currentRadius / (maxDim > 0 ? maxDim : 1)).clamp(0.01, 2.2);

      final glowPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(normX, normY),
          radius: radRatio,
          colors: [
            waveColor.withValues(alpha: (0.24 * smoothFade).clamp(0.0, 1.0)),
            waveColor.withValues(alpha: (0.08 * smoothFade).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
    }

    // 3. Leading Harmonic Ripple Ring
    if (currentRadius > 12) {
      final outerRingPaint = Paint()
        ..color = waveColor.withValues(alpha: (0.4 * fadeOut * fadeOut).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawCircle(origin, (currentRadius + 14).clamp(0.0, double.infinity), outerRingPaint);
    }

    // 4. Primary Luminous Wave Shockwave Crest
    final primaryWavePaint = Paint()
      ..color = waveColor.withValues(alpha: (0.9 * fadeOut * fadeOut).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = (5.0 * fadeOut + 1.0);
    canvas.drawCircle(origin, currentRadius, primaryWavePaint);

    // 5. Secondary Trailing Harmonic Resonance Ring
    if (currentRadius > 32) {
      final secondaryWavePaint = Paint()
        ..color = waveColor.withValues(alpha: (0.5 * fadeOut * fadeOut).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2.5 * fadeOut + 0.6);
      canvas.drawCircle(origin, (currentRadius - 28).clamp(0.0, double.infinity), secondaryWavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ThemeRipplePainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.origin != origin ||
           oldDelegate.waveColor != waveColor ||
           oldDelegate.targetColor != targetColor ||
           oldDelegate.isDark != isDark;
  }
}
