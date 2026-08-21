import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tüm ekranlarda kullanılan animasyonlu yıldızlı gece gökyüzü arka planı.
class StarryBackground extends StatefulWidget {
  final Widget child;

  const StarryBackground({super.key, required this.child});

  @override
  State<StarryBackground> createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final rng = Random(42);
    _stars = List.generate(60, (_) {
      return _Star(
        position: Offset(rng.nextDouble(), rng.nextDouble()),
        radius: rng.nextDouble() * 1.6 + 0.6,
        phase: rng.nextDouble(),
        speed: rng.nextDouble() * 0.6 + 0.4,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark
        ? const [AppColors.bgTop, AppColors.bgMid, AppColors.bgBottom]
        : const [AppColors.dayTop, AppColors.dayMid, AppColors.dayBottom];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gündüz temasında sol üstte yumuşak bir güneş parıltısı.
          if (!isDark)
            Positioned(
              left: -60,
              top: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFF3C4).withValues(alpha: 0.85),
                      const Color(0xFFFFF3C4).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _StarPainter(
                  stars: _stars,
                  t: _controller.value,
                  isDark: isDark,
                ),
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Star {
  final Offset position; // 0..1 normalize edilmiş konum
  final double radius;
  final double phase;
  final double speed;

  const _Star({
    required this.position,
    required this.radius,
    required this.phase,
    required this.speed,
  });
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  final bool isDark;

  _StarPainter({required this.stars, required this.t, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Gece: parlak beyaz yıldızlar. Gündüz: daha soluk, süzülen parıltılar.
    final maxAlpha = isDark ? 1.0 : 0.5;
    final paint = Paint();
    for (final star in stars) {
      // Yanıp sönme efekti.
      final twinkle =
          0.4 + 0.6 * (0.5 + 0.5 * sin(2 * pi * (t * star.speed + star.phase)));
      paint.color = Colors.white.withValues(alpha: twinkle * maxAlpha);
      canvas.drawCircle(
        Offset(star.position.dx * size.width, star.position.dy * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.isDark != isDark;
}
