import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/audio_service.dart';
import '../theme/app_colors.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/starry_background.dart';

/// Kategori geçişini kutlayan yaş pasta ekranı.
///
/// Pastanın üstünde [candleCount] kadar yanan mum vardır. Oyuncu parmağıyla
/// ekranı süpürerek (pan) mumları söndürür; alevin yakınından geçen her mum
/// söner. Tüm mumlar sönünce kısa bir kutlamanın ardından [nextBuilder] ile
/// bir sonraki ekrana geçilir.
class CakeCelebrationScreen extends StatefulWidget {
  /// Yanacak mum sayısı (o ana kadar geçilen kategori sayısı).
  final int candleCount;

  /// Tüm mumlar söndükten sonra açılacak ekran.
  final WidgetBuilder nextBuilder;

  const CakeCelebrationScreen({
    super.key,
    required this.candleCount,
    required this.nextBuilder,
  });

  @override
  State<CakeCelebrationScreen> createState() => _CakeCelebrationScreenState();
}

class _CakeCelebrationScreenState extends State<CakeCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flicker;
  late final ConfettiController _confetti;

  // Sahne ölçüsüne göre bir kez hesaplanan yerleşim.
  double _laidOutWidth = -1;
  double _areaW = 0;
  double _areaH = 0;
  double _cakeTopY = 0;
  double _candleW = 0;
  List<Offset> _flames = const [];

  late List<bool> _lit;
  int _blown = 0;
  bool _done = false;

  int get _count => widget.candleCount;

  @override
  void initState() {
    super.initState();
    _lit = List<bool>.filled(_count, true);
    _flicker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _flicker.dispose();
    _confetti.dispose();
    super.dispose();
  }

  // ---- Yerleşim ------------------------------------------------------------

  void _computeLayout(double maxW) {
    if (_laidOutWidth == maxW) return;
    final w = min(maxW, 360.0);

    final areaW = w * 0.9;
    const desiredSlot = 26.0;
    int perRow = max(1, (areaW / desiredSlot).floor());
    perRow = min(perRow, _count);
    int rows = (_count / perRow).ceil();
    // En fazla 5 sıra: daha fazlaysa satır başına mumu artır.
    if (rows > 5) {
      rows = 5;
      perRow = (_count / rows).ceil();
    }
    final slot = areaW / perRow;
    final candleW = min(16.0, slot * 0.5);

    const candleH = 40.0; // ön sıra mum yüksekliği
    const flameGap = 11.0; // alev merkezi ile mum ucu arası
    const rowGap = 20.0; // arka sıralar yukarıda görünsün
    const topPad = 44.0;

    // Tüm mum tabanları pasta yüzeyinde biter; arka sıra mumları daha uzundur.
    final cakeTopY = topPad + (rows - 1) * rowGap + candleH;

    final flames = <Offset>[];
    for (var i = 0; i < _count; i++) {
      final row = i ~/ perRow;
      final col = i % perRow;
      final countInRow = (row == rows - 1) ? _count - perRow * row : perRow;
      final rowW = countInRow * slot;
      final startX = (w - rowW) / 2 + slot / 2;
      final x = startX + col * slot;
      final candleTopY = topPad + row * rowGap;
      flames.add(Offset(x, candleTopY - flameGap));
    }

    _laidOutWidth = maxW;
    _areaW = w;
    _cakeTopY = cakeTopY;
    _candleW = candleW;
    _flames = flames;
    _areaH = cakeTopY + 150; // pasta gövdesi + tabak
  }

  // ---- Söndürme ------------------------------------------------------------

  void _handlePan(Offset local) {
    if (_done) return;
    final threshold = max(22.0, _candleW * 2.2);
    var changed = false;
    for (var i = 0; i < _flames.length; i++) {
      if (!_lit[i]) continue;
      if ((local - _flames[i]).distance <= threshold) {
        _lit[i] = false;
        _blown++;
        changed = true;
      }
    }
    if (changed) {
      HapticFeedback.lightImpact();
      setState(() {});
      if (_blown >= _count) _finish();
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _flicker.stop();
    _confetti.play();
    AudioService.instance.playClap();
    setState(() {});
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: widget.nextBuilder),
      );
    });
  }

  // ---- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StarryBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    _done ? 'Tebrikler! 🎉' : 'Mumları üfle! 🎂',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _done
                        ? 'Yeni kategori açılıyor...'
                        : 'Parmağınla ekranı süpürerek söndür',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_blown / $_count',
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sunny,
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _computeLayout(constraints.maxWidth);
                        return Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (d) => _handlePan(d.localPosition),
                            onPanUpdate: (d) => _handlePan(d.localPosition),
                            child: SizedBox(
                              width: _areaW,
                              height: _areaH,
                              child: AnimatedBuilder(
                                animation: _flicker,
                                builder: (context, _) => CustomPaint(
                                  painter: _CakePainter(
                                    flames: _flames,
                                    lit: _lit,
                                    cakeTopY: _cakeTopY,
                                    candleW: _candleW,
                                    flick: _flicker.value,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            ConfettiOverlay(controller: _confetti),
          ],
        ),
      ),
    );
  }
}

/// Pastayı, mumları ve alevleri çizen ressam.
class _CakePainter extends CustomPainter {
  final List<Offset> flames;
  final List<bool> lit;
  final double cakeTopY;
  final double candleW;
  final double flick;

  static const _candleColors = [
    AppColors.coral,
    AppColors.mint,
    AppColors.sky,
    AppColors.sunny,
    AppColors.grape,
  ];

  _CakePainter({
    required this.flames,
    required this.lit,
    required this.cakeTopY,
    required this.candleW,
    required this.flick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintCake(canvas, size);

    // Mum gövdeleri (arka sıralar önce -> ön sıralar üste biner).
    for (var i = 0; i < flames.length; i++) {
      final f = flames[i];
      final top = f.dy + 11; // mum ucu (alevin hemen altı)
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(f.dx - candleW / 2, top, f.dx + candleW / 2, cakeTopY + 8),
        Radius.circular(candleW * 0.35),
      );
      final color = _candleColors[i % _candleColors.length];
      canvas.drawRRect(rect, Paint()..color = color);
      // Beyaz çizgi (mum deseni).
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(f.dx - candleW * 0.12, top, f.dx + candleW * 0.12, cakeTopY),
          Radius.circular(candleW * 0.12),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
      // Fitil.
      canvas.drawLine(
        Offset(f.dx, top),
        Offset(f.dx, top - 5),
        Paint()
          ..color = const Color(0xFF3A2E2E)
          ..strokeWidth = 2,
      );
    }

    // Alevler (yananlar) veya duman (sönmüşler) — mumların üstünde.
    for (var i = 0; i < flames.length; i++) {
      if (lit[i]) {
        _paintFlame(canvas, flames[i], i);
      }
    }
  }

  void _paintFlame(Canvas canvas, Offset c, int i) {
    // Titreşim: her mum için hafif faz kaymalı ölçek.
    final phase = flick * 2 * pi + i * 1.3;
    final s = 0.85 + 0.2 * sin(phase);
    final h = 18.0 * s;
    final w = 9.0 * s;

    // Dış alev (turuncu).
    final outer = Path()
      ..moveTo(c.dx, c.dy - h)
      ..quadraticBezierTo(c.dx + w, c.dy - h * 0.2, c.dx, c.dy + h * 0.35)
      ..quadraticBezierTo(c.dx - w, c.dy - h * 0.2, c.dx, c.dy - h)
      ..close();
    canvas.drawPath(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE082), Color(0xFFFF7043)],
        ).createShader(Rect.fromCircle(center: c, radius: h)),
    );
    // İç alev (sarı).
    final inner = Path()
      ..moveTo(c.dx, c.dy - h * 0.6)
      ..quadraticBezierTo(c.dx + w * 0.5, c.dy - h * 0.1, c.dx, c.dy + h * 0.2)
      ..quadraticBezierTo(c.dx - w * 0.5, c.dy - h * 0.1, c.dx, c.dy - h * 0.6)
      ..close();
    canvas.drawPath(inner, Paint()..color = const Color(0xFFFFF3B0));
    // Sıcak parıltı.
    canvas.drawCircle(
      c,
      h * 0.9,
      Paint()
        ..color = const Color(0xFFFFC93C).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _paintCake(Canvas canvas, Size size) {
    final w = size.width;
    final left = w * 0.06;
    final right = w * 0.94;
    final top = cakeTopY;
    final bottom = cakeTopY + 120;

    // Tabak.
    canvas.drawOval(
      Rect.fromLTWH(left - 14, bottom - 10, (right - left) + 28, 34),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    // Alt kek gövdesi.
    final body = RRect.fromRectAndCorners(
      Rect.fromLTRB(left, top + 26, right, bottom),
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
      bottomLeft: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFEBA6C6));

    // Üst krema (dalgalı alt kenarlı).
    final frosting = Path()..moveTo(left, top + 30);
    const waves = 6;
    final span = (right - left) / waves;
    for (var i = 0; i < waves; i++) {
      final x0 = left + i * span;
      frosting.quadraticBezierTo(
        x0 + span * 0.25, top + 46,
        x0 + span * 0.5, top + 34,
      );
      frosting.quadraticBezierTo(
        x0 + span * 0.75, top + 24,
        x0 + span, top + 34,
      );
    }
    frosting
      ..lineTo(right, top + 4)
      ..lineTo(left, top + 4)
      ..close();
    canvas.drawPath(frosting, Paint()..color = const Color(0xFFFFF3F8));

    // Krema üstü ince şerit.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top - 2, right, top + 8),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFFDE1EC),
    );

    // Şeker taneleri (sprinkles).
    final rnd = Random(7);
    const sprinkleColors = [
      AppColors.coral,
      AppColors.mint,
      AppColors.sky,
      AppColors.sunny,
      AppColors.grape,
    ];
    for (var i = 0; i < 14; i++) {
      final sx = left + 12 + rnd.nextDouble() * (right - left - 24);
      final sy = top + 44 + rnd.nextDouble() * 60;
      final p = Paint()..color = sprinkleColors[i % sprinkleColors.length];
      canvas.save();
      canvas.translate(sx, sy);
      canvas.rotate(rnd.nextDouble() * pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -1.5, 8, 3),
          const Radius.circular(1.5),
        ),
        p,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CakePainter old) => true;
}
