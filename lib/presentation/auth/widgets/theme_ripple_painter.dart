import 'dart:math' as math;
import 'package:flutter/material.dart';

class ThemeRipplePainter extends CustomPainter {
  final double progress;
  final Offset origin;
  final Color targetColor;
  final Color waveColor;

  ThemeRipplePainter({
    required this.progress,
    required this.origin,
    required this.targetColor,
    required this.waveColor,
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

    // Initial origin spark flash (first 25% of animation)
    final sparkProgress = (progress / 0.25).clamp(0.0, 1.0);
    if (sparkProgress < 1.0) {
      final sparkFade = 1.0 - sparkProgress;
      final sparkPaint = Paint()
        ..color = waveColor.withValues(alpha: (0.45 * sparkFade).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(origin, 28 * sparkProgress + 4, sparkPaint);
    }

    // Soft radiant expanding aura
    if (smoothFade > 0.01) {
      final normX = (size.width > 0 ? (origin.dx / size.width) * 2 - 1 : 0.0).clamp(-1.0, 1.0);
      final normY = (size.height > 0 ? (origin.dy / size.height) * 2 - 1 : 0.0).clamp(-1.0, 1.0);
      final double maxDim = math.max(size.width, size.height);
      final radRatio = (currentRadius / (maxDim > 0 ? maxDim : 1)).clamp(0.01, 2.0);

      final glowPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(normX, normY),
          radius: radRatio,
          colors: [
            waveColor.withValues(alpha: (0.16 * smoothFade).clamp(0.0, 1.0)),
            waveColor.withValues(alpha: (0.05 * smoothFade).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.8, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
    }

    // Outer harmonic ripple ring
    if (currentRadius > 15) {
      final outerRingPaint = Paint()
        ..color = waveColor.withValues(alpha: (0.35 * fadeOut * fadeOut).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(origin, (currentRadius + 12).clamp(0.0, double.infinity), outerRingPaint);
    }

    // Primary wavefront crest (luminous shockwave accent)
    final primaryWavePaint = Paint()
      ..color = waveColor.withValues(alpha: (0.85 * fadeOut * fadeOut).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = (4.0 * fadeOut + 0.8);
    canvas.drawCircle(origin, currentRadius, primaryWavePaint);

    // Inner secondary trailing resonance ring
    if (currentRadius > 35) {
      final secondaryWavePaint = Paint()
        ..color = waveColor.withValues(alpha: (0.45 * fadeOut * fadeOut).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2.0 * fadeOut + 0.5);
      canvas.drawCircle(origin, (currentRadius - 26).clamp(0.0, double.infinity), secondaryWavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ThemeRipplePainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.origin != origin ||
           oldDelegate.waveColor != waveColor ||
           oldDelegate.targetColor != targetColor;
  }
}
