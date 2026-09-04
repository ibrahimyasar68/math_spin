import 'dart:math';

import 'package:flutter/material.dart';

/// Puzzle resimlerini çizen hayvan portreleri.
///
/// Hepsi kare bir tuvale, ölçüye göre oranlanmış koordinatlarla çizer
/// ([mascot.dart] ile aynı teknik): `w * 0.5` gibi. Böylece resim her boyutta
/// keskin durur ve puzzle parçalarının kırpılması piksel hesabı gerektirmez —
/// parça, tam resmi kaydırıp kırpar.
///
/// Yeni bir hayvan eklemek için: buraya bir [AnimalPainter] alt sınıfı yaz,
/// `puzzle_image.dart` içindeki listeye bir satır ekle. Başka yeri değişmez.
abstract class AnimalPainter extends CustomPainter {
  const AnimalPainter();

  /// Tüm hayvanlarda ortak koyu kontur rengi.
  static const outline = Color(0xFF2A1B4D);

  /// Konturu ölçüye göre kalınlaşan çizgi fırçası.
  Paint strokeOf(double w, [double scale = 1]) => Paint()
    ..color = outline
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.022 * scale
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Dolgu + kontur birlikte: hayvanların tüm gövde parçaları böyle çizilir.
  void fillStroke(Canvas canvas, Path path, Color color, double w,
      [double strokeScale = 1]) {
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, strokeOf(w, strokeScale));
  }

  /// Büyük, parlak göz: koyu badem + iki beyaz ışık noktası.
  void drawEye(Canvas canvas, Offset c, double r) {
    canvas.drawOval(
      Rect.fromCenter(center: c, width: r * 1.7, height: r * 2),
      Paint()..color = outline,
    );
    canvas.drawCircle(
      c.translate(-r * 0.28, -r * 0.42),
      r * 0.42,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      c.translate(r * 0.34, r * 0.36),
      r * 0.2,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  /// Yanak pembeliği.
  void drawBlush(Canvas canvas, Offset c, double rx, double ry) {
    canvas.drawOval(
      Rect.fromCenter(center: c, width: rx * 2, height: ry * 2),
      Paint()..color = const Color(0xFFFF8FA8).withValues(alpha: 0.55),
    );
  }

  /// Gülümseme: burnun altından iki yana açılan çift yay.
  void drawSmile(Canvas canvas, double w, Offset from, double spread) {
    final p = Path()
      ..moveTo(from.dx - spread, from.dy)
      ..quadraticBezierTo(
          from.dx - spread * 0.5, from.dy + spread * 0.8, from.dx, from.dy)
      ..quadraticBezierTo(
          from.dx + spread * 0.5, from.dy + spread * 0.8, from.dx + spread,
          from.dy);
    canvas.drawPath(p, strokeOf(w, 0.85));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// At: uzun yüz, yeleli, üçgen kulaklı.
class HorsePainter extends AnimalPainter {
  const HorsePainter();

  static const _coat = Color(0xFFCE8A48);
  static const _coatDark = Color(0xFFB0713A);
  static const _mane = Color(0xFF6B4226);
  static const _muzzle = Color(0xFFF0D2AE);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Kulaklar (üçgen, hafif dışa yatık).
    for (final sign in [-1.0, 1.0]) {
      final x = w * (0.5 + sign * 0.22);
      final ear = Path()
        ..moveTo(x - w * 0.055, h * 0.30)
        ..lineTo(x + sign * w * 0.02, h * 0.09)
        ..lineTo(x + w * 0.075, h * 0.28)
        ..close();
      fillStroke(canvas, ear, _coatDark, w);
    }

    // Yüz: yukarısı geniş, aşağıya doğru incelen uzun oval.
    final face = Path()
      ..moveTo(w * 0.5, h * 0.16)
      ..cubicTo(w * 0.82, h * 0.18, w * 0.86, h * 0.44, w * 0.74, h * 0.66)
      ..cubicTo(w * 0.68, h * 0.80, w * 0.62, h * 0.90, w * 0.5, h * 0.90)
      ..cubicTo(w * 0.38, h * 0.90, w * 0.32, h * 0.80, w * 0.26, h * 0.66)
      ..cubicTo(w * 0.14, h * 0.44, w * 0.18, h * 0.18, w * 0.5, h * 0.16)
      ..close();
    fillStroke(canvas, face, _coat, w);

    // Alından buruna inen beyaz akıtma.
    final blaze = Path()
      ..moveTo(w * 0.5, h * 0.20)
      ..cubicTo(w * 0.57, h * 0.30, w * 0.56, h * 0.52, w * 0.53, h * 0.68)
      ..lineTo(w * 0.47, h * 0.68)
      ..cubicTo(w * 0.44, h * 0.52, w * 0.43, h * 0.30, w * 0.5, h * 0.20)
      ..close();
    canvas.drawPath(blaze, Paint()..color = Colors.white.withValues(alpha: 0.85));

    // Yele: alnın üstünde dalgalı bir tutam.
    final mane = Path()
      ..moveTo(w * 0.30, h * 0.26)
      ..quadraticBezierTo(w * 0.34, h * 0.06, w * 0.46, h * 0.11)
      ..quadraticBezierTo(w * 0.50, h * 0.01, w * 0.58, h * 0.10)
      ..quadraticBezierTo(w * 0.70, h * 0.05, w * 0.71, h * 0.27)
      ..quadraticBezierTo(w * 0.50, h * 0.19, w * 0.30, h * 0.26)
      ..close();
    fillStroke(canvas, mane, _mane, w);

    // Burun bölgesi.
    final muzzle = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.755),
          width: w * 0.42,
          height: h * 0.26));
    fillStroke(canvas, muzzle, _muzzle, w, 0.9);

    // Burun delikleri.
    for (final sign in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * (0.5 + sign * 0.10), h * 0.73),
          width: w * 0.055,
          height: h * 0.075,
        ),
        Paint()..color = AnimalPainter.outline,
      );
    }

    drawSmile(canvas, w, Offset(w * 0.5, h * 0.82), w * 0.07);
    drawEye(canvas, Offset(w * 0.34, h * 0.46), w * 0.062);
    drawEye(canvas, Offset(w * 0.66, h * 0.46), w * 0.062);
    drawBlush(canvas, Offset(w * 0.26, h * 0.58), w * 0.06, h * 0.035);
    drawBlush(canvas, Offset(w * 0.74, h * 0.58), w * 0.06, h * 0.035);
  }
}

/// Ayı: yuvarlak kafa, tepede iki yuvarlak kulak, açık renk ağızlık.
class BearPainter extends AnimalPainter {
  const BearPainter();

  static const _fur = Color(0xFFB07A4E);
  static const _furDark = Color(0xFF9A6740);
  static const _muzzle = Color(0xFFF2DCC4);
  static const _innerEar = Color(0xFFE0A9A0);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Kulaklar.
    for (final sign in [-1.0, 1.0]) {
      final c = Offset(w * (0.5 + sign * 0.27), h * 0.26);
      fillStroke(
        canvas,
        Path()..addOval(Rect.fromCircle(center: c, radius: w * 0.135)),
        _furDark,
        w,
      );
      canvas.drawCircle(c, w * 0.072, Paint()..color = _innerEar);
    }

    // Kafa.
    final head = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.56),
          width: w * 0.76,
          height: h * 0.68));
    fillStroke(canvas, head, _fur, w);

    // Ağızlık.
    final muzzle = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.70),
          width: w * 0.44,
          height: h * 0.32));
    fillStroke(canvas, muzzle, _muzzle, w, 0.85);

    // Burun.
    final nose = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.635),
            width: w * 0.16,
            height: h * 0.105),
        Radius.circular(w * 0.05),
      ));
    canvas.drawPath(nose, Paint()..color = AnimalPainter.outline);

    // Burundan aşağı inen çizgi + gülümseme.
    canvas.drawLine(
      Offset(w * 0.5, h * 0.69),
      Offset(w * 0.5, h * 0.755),
      strokeOf(w, 0.85),
    );
    drawSmile(canvas, w, Offset(w * 0.5, h * 0.755), w * 0.085);

    drawEye(canvas, Offset(w * 0.35, h * 0.50), w * 0.058);
    drawEye(canvas, Offset(w * 0.65, h * 0.50), w * 0.058);
    drawBlush(canvas, Offset(w * 0.23, h * 0.63), w * 0.065, h * 0.04);
    drawBlush(canvas, Offset(w * 0.77, h * 0.63), w * 0.065, h * 0.04);
  }
}

/// Tavşan: uzun kulaklar, üçgen pembe burun, bıyıklar.
class RabbitPainter extends AnimalPainter {
  const RabbitPainter();

  static const _fur = Color(0xFFF3EDF7);
  static const _furShade = Color(0xFFDCD2E6);
  static const _innerEar = Color(0xFFFFB3C6);
  static const _nose = Color(0xFFFF7DA0);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Kulaklar: dışa doğru hafif eğik uzun ovaller.
    for (final sign in [-1.0, 1.0]) {
      final cx = w * (0.5 + sign * 0.155);
      canvas.save();
      canvas.translate(cx, h * 0.30);
      canvas.rotate(sign * 0.16);
      final ear = Path()
        ..addOval(Rect.fromCenter(
            center: Offset.zero, width: w * 0.175, height: h * 0.50));
      fillStroke(canvas, ear, _fur, w);
      canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(0, 6), width: w * 0.09, height: h * 0.36),
        Paint()..color = _innerEar,
      );
      canvas.restore();
    }

    // Kafa.
    final head = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.665),
          width: w * 0.66,
          height: h * 0.58));
    fillStroke(canvas, head, _fur, w);

    // Yanaklar (hafif gölge, kafanın altına hacim verir).
    for (final sign in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * (0.5 + sign * 0.17), h * 0.755),
          width: w * 0.26,
          height: h * 0.20,
        ),
        Paint()..color = _furShade.withValues(alpha: 0.7),
      );
    }

    // Bıyıklar.
    for (final sign in [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        final y = h * (0.71 + i * 0.045);
        canvas.drawLine(
          Offset(w * (0.5 + sign * 0.13), y),
          Offset(w * (0.5 + sign * 0.40), y - h * (0.03 - i * 0.03)),
          strokeOf(w, 0.55),
        );
      }
    }

    // Burun (üçgen) ve ağız.
    final nose = Path()
      ..moveTo(w * 0.5 - w * 0.055, h * 0.695)
      ..lineTo(w * 0.5 + w * 0.055, h * 0.695)
      ..lineTo(w * 0.5, h * 0.745)
      ..close();
    fillStroke(canvas, nose, _nose, w, 0.75);
    canvas.drawLine(
      Offset(w * 0.5, h * 0.745),
      Offset(w * 0.5, h * 0.785),
      strokeOf(w, 0.75),
    );
    drawSmile(canvas, w, Offset(w * 0.5, h * 0.785), w * 0.07);

    // Ön dişler.
    final teeth = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.845),
            width: w * 0.10,
            height: h * 0.075),
        Radius.circular(w * 0.02),
      ));
    fillStroke(canvas, teeth, Colors.white, w, 0.6);
    canvas.drawLine(
      Offset(w * 0.5, h * 0.812),
      Offset(w * 0.5, h * 0.878),
      strokeOf(w, 0.5),
    );

    drawEye(canvas, Offset(w * 0.355, h * 0.61), w * 0.06);
    drawEye(canvas, Offset(w * 0.645, h * 0.61), w * 0.06);
    drawBlush(canvas, Offset(w * 0.245, h * 0.71), w * 0.06, h * 0.035);
    drawBlush(canvas, Offset(w * 0.755, h * 0.71), w * 0.06, h * 0.035);
  }
}

/// Çizimlerin arkasındaki yumuşak zemin dairesi — parçalar açıldığında
/// resmin sınırları belli olsun diye.
class AnimalBackdrop extends CustomPainter {
  final Color color;

  const AnimalBackdrop(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final r = min(size.width, size.height) * 0.5;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [color, Color.lerp(color, Colors.black, 0.22)!],
        ).createShader(
          Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.45), radius: r),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant AnimalBackdrop oldDelegate) =>
      oldDelegate.color != color;
}
