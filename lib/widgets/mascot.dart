import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Maskotun anlık ruh hali.
enum MascotMood { idle, happy, sad, thinking }

/// Maskotun değiştirilebilir görünümü (renk/kostüm).
class MascotSkin {
  final String name;
  final Color headTop;
  final Color headBottom;
  final Color ear;
  final Color antenna;

  const MascotSkin({
    required this.name,
    required this.headTop,
    required this.headBottom,
    required this.ear,
    required this.antenna,
  });
}

/// Varsayılan avatar (sabit — Mascot için const varsayılan değer).
const MascotSkin kDefaultMascotSkin = MascotSkin(
  name: 'Üzüm',
  headTop: AppColors.grape,
  headBottom: Color(0xFF8A5BE0),
  ear: AppColors.sky,
  antenna: AppColors.sunny,
);

/// Seçilebilir hazır avatarlar.
const List<MascotSkin> mascotSkins = [
  kDefaultMascotSkin,
  MascotSkin(
    name: 'Nane',
    headTop: AppColors.mint,
    headBottom: Color(0xFF3DA877),
    ear: AppColors.coral,
    antenna: AppColors.sunny,
  ),
  MascotSkin(
    name: 'Mercan',
    headTop: AppColors.coral,
    headBottom: Color(0xFFD8506F),
    ear: AppColors.grape,
    antenna: AppColors.sky,
  ),
  MascotSkin(
    name: 'Gökyüzü',
    headTop: AppColors.sky,
    headBottom: Color(0xFF3A7FB8),
    ear: AppColors.mint,
    antenna: AppColors.sunny,
  ),
  MascotSkin(
    name: 'Güneş',
    headTop: AppColors.sunny,
    headBottom: Color(0xFFE0A413),
    ear: AppColors.grape,
    antenna: AppColors.coral,
  ),
  // Ödül avatarı: oyun bitirilene kadar kilitli (bkz. [championSkinIndex]).
  MascotSkin(
    name: 'Şampiyon',
    headTop: Color(0xFFFFE27A),
    headBottom: Color(0xFFC98A10),
    ear: Color(0xFFFFF3C4),
    antenna: AppColors.coral,
  ),
];

/// Ödül avatarının [mascotSkins] içindeki indeksi.
///
/// Oyun bitirilene kadar seçiciye kilitli görünür; kilidi
/// `ProgressStore.completed` açar.
const int championSkinIndex = 5;

/// Oyuna kişilik katan, ifade değiştiren ve hafifçe sallanan robot maskot.
class Mascot extends StatefulWidget {
  final MascotMood mood;
  final MascotSkin skin;
  final double size;

  const Mascot({
    super.key,
    this.mood = MascotMood.idle,
    this.skin = kDefaultMascotSkin,
    this.size = 96,
  });

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with TickerProviderStateMixin {
  late final AnimationController _bob; // sürekli yukarı-aşağı süzülme
  late final AnimationController _react; // ruh hali değişiminde zıplama

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _react = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..value = 1;
  }

  @override
  void didUpdateWidget(covariant Mascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ruh hali ya da avatar değişince kısa bir zıplama tepkisi ver.
    if (oldWidget.mood != widget.mood ||
        oldWidget.skin.name != widget.skin.name) {
      _react.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    _react.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bob, _react]),
      builder: (context, _) {
        final bobDy = sin(_bob.value * pi) * 4 - 2;
        final pop = 1 + 0.12 * Curves.elasticOut.transform(_react.value) -
            0.12; // hafif zıplama
        return Transform.translate(
          offset: Offset(0, bobDy),
          child: Transform.scale(
            scale: pop.clamp(0.85, 1.15),
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _MascotPainter(
                mood: widget.mood,
                skin: widget.skin,
                blink: _bob.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MascotPainter extends CustomPainter {
  final MascotMood mood;
  final MascotSkin skin;
  final double blink;

  _MascotPainter({
    required this.mood,
    required this.skin,
    required this.blink,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.22, w * 0.76, h * 0.66),
      Radius.circular(w * 0.28),
    );

    // Anten.
    final antennaPaint = Paint()
      ..color = skin.antenna
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.22),
      Offset(w * 0.5, h * 0.08),
      antennaPaint,
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.07),
      w * 0.06,
      Paint()..color = skin.antenna,
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.07),
      w * 0.06,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.015,
    );

    // Kafa gövdesi (gradyan).
    final headPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skin.headTop, skin.headBottom],
      ).createShader(headRect.outerRect);
    canvas.drawRRect(headRect, headPaint);
    canvas.drawRRect(
      headRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03,
    );

    // Yüz ekranı (koyu panel).
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.34, w * 0.56, h * 0.42),
      Radius.circular(w * 0.16),
    );
    canvas.drawRRect(faceRect, Paint()..color = const Color(0xFF14102E));

    _drawFace(canvas, size);

    // Kulaklar.
    final earPaint = Paint()..color = skin.ear;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.04, h * 0.42, w * 0.09, h * 0.22),
        Radius.circular(w * 0.04),
      ),
      earPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.87, h * 0.42, w * 0.09, h * 0.22),
        Radius.circular(w * 0.04),
      ),
      earPaint,
    );
  }

  void _drawFace(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final eyePaint = Paint()..color = Colors.white;
    final eyeY = h * 0.48;
    final lEye = Offset(w * 0.37, eyeY);
    final rEye = Offset(w * 0.63, eyeY);

    // Periyodik göz kırpma (bob döngüsünün tepesinde).
    final blinking = blink > 0.92;

    void drawEye(Offset c) {
      if (mood == MascotMood.happy) {
        // Mutlu: yıldız/parıltılı gözler.
        _drawStar(canvas, c, w * 0.075, AppColors.sunny);
      } else if (blinking) {
        canvas.drawLine(
          Offset(c.dx - w * 0.06, c.dy),
          Offset(c.dx + w * 0.06, c.dy),
          Paint()
            ..color = Colors.white
            ..strokeWidth = w * 0.03
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawCircle(c, w * 0.07, eyePaint);
        // Bakış yönü: düşünürken yukarı, üzgünken aşağı.
        final dy = mood == MascotMood.thinking
            ? -w * 0.025
            : (mood == MascotMood.sad ? w * 0.02 : 0.0);
        canvas.drawCircle(
          Offset(c.dx, c.dy + dy),
          w * 0.032,
          Paint()..color = AppColors.ink,
        );
      }
    }

    drawEye(lEye);
    drawEye(rEye);

    // Ağız.
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    final mouthCenter = Offset(w * 0.5, h * 0.64);
    final mw = w * 0.18;
    final path = Path();

    switch (mood) {
      case MascotMood.happy:
        path.moveTo(mouthCenter.dx - mw, mouthCenter.dy - h * 0.01);
        path.quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + h * 0.08,
            mouthCenter.dx + mw, mouthCenter.dy - h * 0.01);
        break;
      case MascotMood.sad:
        path.moveTo(mouthCenter.dx - mw, mouthCenter.dy + h * 0.04);
        path.quadraticBezierTo(mouthCenter.dx, mouthCenter.dy - h * 0.05,
            mouthCenter.dx + mw, mouthCenter.dy + h * 0.04);
        break;
      case MascotMood.thinking:
        // Düz/küçük ağız, hafif yana kayık.
        path.moveTo(mouthCenter.dx - mw * 0.5, mouthCenter.dy);
        path.lineTo(mouthCenter.dx + mw * 0.7, mouthCenter.dy - h * 0.015);
        break;
      case MascotMood.idle:
        path.moveTo(mouthCenter.dx - mw * 0.8, mouthCenter.dy);
        path.quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + h * 0.04,
            mouthCenter.dx + mw * 0.8, mouthCenter.dy);
        break;
    }
    canvas.drawPath(path, mouthPaint);

    // Yanak (mutluyken pembe).
    if (mood == MascotMood.happy) {
      final cheek = Paint()..color = AppColors.coral.withValues(alpha: 0.55);
      canvas.drawCircle(Offset(w * 0.3, h * 0.6), w * 0.04, cheek);
      canvas.drawCircle(Offset(w * 0.7, h * 0.6), w * 0.04, cheek);
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final outer = i * 4 * pi / 5 - pi / 2;
      final inner = outer + 2 * pi / 5;
      final po = Offset(c.dx + r * cos(outer), c.dy + r * sin(outer));
      final pi2 = Offset(
          c.dx + r * 0.45 * cos(inner), c.dy + r * 0.45 * sin(inner));
      if (i == 0) {
        path.moveTo(po.dx, po.dy);
      } else {
        path.lineTo(po.dx, po.dy);
      }
      path.lineTo(pi2.dx, pi2.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.blink != blink ||
      oldDelegate.skin.name != skin.name;
}
