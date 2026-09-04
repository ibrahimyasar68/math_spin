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

  /// Tırtıklı daire: kenarı [bumps] kadar yumruyla dalgalanan bir çember.
  /// Aslanın yelesi ve koyunun yünü bununla çiziliyor.
  Path bumpyCircle(Offset c, double r, int bumps, double amp) {
    final path = Path();
    const steps = 240;
    for (var i = 0; i <= steps; i++) {
      final a = i / steps * 2 * pi;
      final rr = r * (1 + amp * sin(a * bumps));
      final pt = Offset(c.dx + rr * cos(a), c.dy + rr * sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  /// Üçgen kulak (kedi, tilki): [tip] uca, [a]-[b] tabana denk gelir.
  Path triangleEar(Offset a, Offset tip, Offset b) =>
      Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(b.dx, b.dy)
        ..close();

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

/// Kedi: üçgen kulaklar, üç bıyık, küçük pembe burun.
class CatPainter extends AnimalPainter {
  const CatPainter();

  static const _fur = Color(0xFF9FA8C9);
  static const _furDark = Color(0xFF8791B6);
  static const _innerEar = Color(0xFFF6B8C8);
  static const _muzzle = Color(0xFFF3F1F8);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    for (final sign in [-1.0, 1.0]) {
      final x = w * (0.5 + sign * 0.26);
      final ear = triangleEar(
        Offset(x - w * 0.11, h * 0.44),
        Offset(x + sign * w * 0.05, h * 0.13),
        Offset(x + w * 0.11, h * 0.42),
      );
      fillStroke(canvas, ear, _furDark, w);
      canvas.drawPath(
        triangleEar(
          Offset(x - w * 0.055, h * 0.40),
          Offset(x + sign * w * 0.035, h * 0.21),
          Offset(x + w * 0.055, h * 0.39),
        ),
        Paint()..color = _innerEar,
      );
    }

    final head = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.58),
          width: w * 0.74,
          height: h * 0.62));
    fillStroke(canvas, head, _fur, w);

    // Alındaki çizgiler.
    for (final dx in [-0.07, 0.0, 0.07]) {
      canvas.drawLine(
        Offset(w * (0.5 + dx), h * 0.34),
        Offset(w * (0.5 + dx), h * 0.42),
        strokeOf(w, 0.6),
      );
    }

    // Ağızlık: iki yanak yumrusu.
    for (final sign in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * (0.5 + sign * 0.10), h * 0.72),
          width: w * 0.26,
          height: h * 0.20,
        ),
        Paint()..color = _muzzle,
      );
    }

    // Bıyıklar.
    for (final sign in [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        final y = h * (0.68 + i * 0.045);
        canvas.drawLine(
          Offset(w * (0.5 + sign * 0.16), y),
          Offset(w * (0.5 + sign * 0.44), y - h * (0.035 - i * 0.035)),
          strokeOf(w, 0.5),
        );
      }
    }

    final nose = triangleEar(
      Offset(w * 0.455, h * 0.665),
      Offset(w * 0.5, h * 0.715),
      Offset(w * 0.545, h * 0.665),
    );
    fillStroke(canvas, nose, _innerEar, w, 0.7);
    drawSmile(canvas, w, Offset(w * 0.5, h * 0.715), w * 0.075);

    drawEye(canvas, Offset(w * 0.355, h * 0.56), w * 0.06);
    drawEye(canvas, Offset(w * 0.645, h * 0.56), w * 0.06);
    drawBlush(canvas, Offset(w * 0.245, h * 0.66), w * 0.06, h * 0.033);
    drawBlush(canvas, Offset(w * 0.755, h * 0.66), w * 0.06, h * 0.033);
  }
}

/// Köpek: yanlarda sarkan kulaklar, büyük ağızlık, siyah burun.
class DogPainter extends AnimalPainter {
  const DogPainter();

  static const _fur = Color(0xFFE0AE72);
  static const _ear = Color(0xFF9C6B3F);
  static const _muzzle = Color(0xFFF7E7D2);
  static const _tongue = Color(0xFFF98BA0);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sarkan kulaklar (kafanın arkasından iner).
    for (final sign in [-1.0, 1.0]) {
      final ear = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(w * (0.5 + sign * 0.35), h * 0.55),
          width: w * 0.24,
          height: h * 0.50,
        ));
      fillStroke(canvas, ear, _ear, w);
    }

    final head = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.53),
          width: w * 0.66,
          height: h * 0.60));
    fillStroke(canvas, head, _fur, w);

    final muzzle = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.71),
          width: w * 0.44,
          height: h * 0.30));
    fillStroke(canvas, muzzle, _muzzle, w, 0.85);

    final nose = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.635),
          width: w * 0.15,
          height: h * 0.11));
    canvas.drawPath(nose, Paint()..color = AnimalPainter.outline);

    canvas.drawLine(
      Offset(w * 0.5, h * 0.69),
      Offset(w * 0.5, h * 0.75),
      strokeOf(w, 0.8),
    );
    drawSmile(canvas, w, Offset(w * 0.5, h * 0.75), w * 0.085);

    // Dil.
    final tongue = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.83),
            width: w * 0.11,
            height: h * 0.09),
        Radius.circular(w * 0.05),
      ));
    fillStroke(canvas, tongue, _tongue, w, 0.6);

    drawEye(canvas, Offset(w * 0.37, h * 0.48), w * 0.058);
    drawEye(canvas, Offset(w * 0.63, h * 0.48), w * 0.058);
    drawBlush(canvas, Offset(w * 0.27, h * 0.60), w * 0.055, h * 0.032);
    drawBlush(canvas, Offset(w * 0.73, h * 0.60), w * 0.055, h * 0.032);
  }
}

/// Kuş: tepesinde tüy tutamı, turuncu üçgen gaga.
class BirdPainter extends AnimalPainter {
  const BirdPainter();

  static const _body = Color(0xFFFFD35B);
  static const _wing = Color(0xFFF2B93C);
  static const _beak = Color(0xFFF08A2E);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Tepe tüyleri.
    for (final dx in [-0.08, 0.0, 0.08]) {
      final tuft = Path()
        ..moveTo(w * (0.5 + dx) - w * 0.035, h * 0.30)
        ..quadraticBezierTo(w * (0.5 + dx), h * 0.08, w * (0.5 + dx) + w * 0.035,
            h * 0.30)
        ..close();
      fillStroke(canvas, tuft, _wing, w, 0.8);
    }

    final body = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.58),
          width: w * 0.72,
          height: h * 0.62));
    fillStroke(canvas, body, _body, w);

    // Kanat.
    final wing = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.755, h * 0.62),
          width: w * 0.20,
          height: h * 0.34));
    fillStroke(canvas, wing, _wing, w, 0.8);

    // Gaga.
    final beak = triangleEar(
      Offset(w * 0.44, h * 0.60),
      Offset(w * 0.5, h * 0.70),
      Offset(w * 0.56, h * 0.60),
    );
    fillStroke(canvas, beak, _beak, w, 0.8);

    // Ayaklar.
    for (final sign in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(w * (0.5 + sign * 0.10), h * 0.87),
        Offset(w * (0.5 + sign * 0.10), h * 0.94),
        strokeOf(w, 0.9)..color = _beak,
      );
    }

    drawEye(canvas, Offset(w * 0.38, h * 0.50), w * 0.058);
    drawEye(canvas, Offset(w * 0.62, h * 0.50), w * 0.058);
    drawBlush(canvas, Offset(w * 0.29, h * 0.62), w * 0.055, h * 0.032);
    drawBlush(canvas, Offset(w * 0.71, h * 0.62), w * 0.055, h * 0.032);
  }
}

/// Fil: kocaman kulaklar, ortada sarkan hortum, iki küçük diş.
class ElephantPainter extends AnimalPainter {
  const ElephantPainter();

  static const _skin = Color(0xFFA9A7CB);
  static const _skinDark = Color(0xFF908DB8);
  static const _innerEar = Color(0xFFD3A8BC);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    for (final sign in [-1.0, 1.0]) {
      final c = Offset(w * (0.5 + sign * 0.31), h * 0.48);
      fillStroke(
        canvas,
        Path()..addOval(Rect.fromCenter(
            center: c, width: w * 0.40, height: h * 0.52)),
        _skinDark,
        w,
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w * 0.22, height: h * 0.30),
        Paint()..color = _innerEar.withValues(alpha: 0.55),
      );
    }

    final head = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.48),
          width: w * 0.54,
          height: h * 0.52));
    fillStroke(canvas, head, _skin, w);

    // Hortum: aşağı inip ucu hafif kıvrılır.
    final trunk = Path()
      ..moveTo(w * 0.425, h * 0.58)
      ..cubicTo(w * 0.40, h * 0.78, w * 0.45, h * 0.90, w * 0.585, h * 0.88)
      ..lineTo(w * 0.585, h * 0.80)
      ..cubicTo(w * 0.50, h * 0.82, w * 0.475, h * 0.74, w * 0.505, h * 0.58)
      ..close();
    fillStroke(canvas, trunk, _skin, w);

    // Dişler.
    for (final sign in [-1.0, 1.0]) {
      final tusk = triangleEar(
        Offset(w * (0.5 + sign * 0.13), h * 0.66),
        Offset(w * (0.5 + sign * 0.19), h * 0.80),
        Offset(w * (0.5 + sign * 0.17), h * 0.65),
      );
      fillStroke(canvas, tusk, Colors.white, w, 0.6);
    }

    drawEye(canvas, Offset(w * 0.385, h * 0.44), w * 0.055);
    drawEye(canvas, Offset(w * 0.615, h * 0.44), w * 0.055);
    drawBlush(canvas, Offset(w * 0.34, h * 0.56), w * 0.05, h * 0.03);
    drawBlush(canvas, Offset(w * 0.66, h * 0.56), w * 0.05, h * 0.03);
  }
}

/// Aslan: tırtıklı yele, açık renk yüz, bıyıklar.
class LionPainter extends AnimalPainter {
  const LionPainter();

  static const _mane = Color(0xFFCE7C22);
  static const _face = Color(0xFFF2C173);
  static const _muzzle = Color(0xFFFAE6C6);
  static const _nose = Color(0xFF7A4A2B);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w * 0.5, h * 0.53);

    fillStroke(canvas, bumpyCircle(c, w * 0.40, 11, 0.10), _mane, w);

    // Kulaklar yelenin üstünden görünür.
    for (final sign in [-1.0, 1.0]) {
      final ec = Offset(w * (0.5 + sign * 0.25), h * 0.30);
      fillStroke(
        canvas,
        Path()..addOval(Rect.fromCircle(center: ec, radius: w * 0.075)),
        _face,
        w,
        0.8,
      );
    }

    final face = Path()
      ..addOval(Rect.fromCenter(
          center: c, width: w * 0.56, height: h * 0.52));
    fillStroke(canvas, face, _face, w);

    for (final sign in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx + sign * w * 0.10, h * 0.67),
          width: w * 0.24,
          height: h * 0.18,
        ),
        Paint()..color = _muzzle,
      );
      for (var i = 0; i < 2; i++) {
        final y = h * (0.64 + i * 0.05);
        canvas.drawLine(
          Offset(w * (0.5 + sign * 0.15), y),
          Offset(w * (0.5 + sign * 0.36), y - h * (0.025 - i * 0.03)),
          strokeOf(w, 0.5),
        );
      }
    }

    final nose = triangleEar(
      Offset(w * 0.45, h * 0.615),
      Offset(w * 0.5, h * 0.665),
      Offset(w * 0.55, h * 0.615),
    );
    fillStroke(canvas, nose, _nose, w, 0.7);
    drawSmile(canvas, w, Offset(w * 0.5, h * 0.665), w * 0.075);

    drawEye(canvas, Offset(w * 0.375, h * 0.50), w * 0.058);
    drawEye(canvas, Offset(w * 0.625, h * 0.50), w * 0.058);
  }
}

/// Kurbağa: tepede iki göz yumrusu, geniş gülümseme.
class FrogPainter extends AnimalPainter {
  const FrogPainter();

  static const _skin = Color(0xFF74C24E);
  static const _belly = Color(0xFFC7E9A8);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Göz yumruları kafanın üstünde durur.
    for (final sign in [-1.0, 1.0]) {
      final ec = Offset(w * (0.5 + sign * 0.20), h * 0.33);
      fillStroke(
        canvas,
        Path()..addOval(Rect.fromCircle(center: ec, radius: w * 0.145)),
        _skin,
        w,
      );
    }

    final head = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.62),
          width: w * 0.80,
          height: h * 0.54));
    fillStroke(canvas, head, _skin, w);

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.73), width: w * 0.46, height: h * 0.24),
      Paint()..color = _belly,
    );

    // Burun delikleri.
    for (final sign in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(w * (0.5 + sign * 0.06), h * 0.56),
        w * 0.016,
        Paint()..color = AnimalPainter.outline,
      );
    }

    // Geniş gülümseme.
    final mouth = Path()
      ..moveTo(w * 0.28, h * 0.66)
      ..quadraticBezierTo(w * 0.5, h * 0.80, w * 0.72, h * 0.66);
    canvas.drawPath(mouth, strokeOf(w, 1.1));

    drawEye(canvas, Offset(w * 0.30, h * 0.33), w * 0.062);
    drawEye(canvas, Offset(w * 0.70, h * 0.33), w * 0.062);
    drawBlush(canvas, Offset(w * 0.23, h * 0.62), w * 0.06, h * 0.033);
    drawBlush(canvas, Offset(w * 0.77, h * 0.62), w * 0.06, h * 0.033);
  }
}

/// Balık: yandan görünüm, kuyruk ve sırt yüzgeci.
class FishPainter extends AnimalPainter {
  const FishPainter();

  static const _body = Color(0xFFF2803C);
  static const _fin = Color(0xFFD95F22);
  static const _belly = Color(0xFFFBD5A5);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Kuyruk.
    final tail = Path()
      ..moveTo(w * 0.74, h * 0.50)
      ..lineTo(w * 0.95, h * 0.30)
      ..lineTo(w * 0.95, h * 0.70)
      ..close();
    fillStroke(canvas, tail, _fin, w);

    // Sırt yüzgeci.
    final dorsal = Path()
      ..moveTo(w * 0.40, h * 0.30)
      ..quadraticBezierTo(w * 0.50, h * 0.10, w * 0.64, h * 0.34)
      ..close();
    fillStroke(canvas, dorsal, _fin, w, 0.8);

    final body = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.44, h * 0.52),
          width: w * 0.66,
          height: h * 0.48));
    fillStroke(canvas, body, _body, w);

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.42, h * 0.62), width: w * 0.44, height: h * 0.20),
      Paint()..color = _belly,
    );

    // Yan yüzgeç: karnın altında, yatık bir dilim.
    final side = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.705),
          width: w * 0.20,
          height: h * 0.085));
    fillStroke(canvas, side, _fin, w, 0.6);

    // Solungaç çizgisi.
    final gill = Path()
      ..moveTo(w * 0.33, h * 0.36)
      ..quadraticBezierTo(w * 0.28, h * 0.52, w * 0.33, h * 0.68);
    canvas.drawPath(gill, strokeOf(w, 0.7));

    // Ağız: gövdenin sol ucunda küçük bir yay.
    final mouth = Path()
      ..moveTo(w * 0.135, h * 0.545)
      ..quadraticBezierTo(w * 0.175, h * 0.60, w * 0.225, h * 0.565);
    canvas.drawPath(mouth, strokeOf(w, 0.8));

    drawEye(canvas, Offset(w * 0.245, h * 0.44), w * 0.055);
    drawBlush(canvas, Offset(w * 0.21, h * 0.53), w * 0.04, h * 0.024);
  }
}

/// Koyun: tırtıklı yün, açık yüz, yanlarda sarkan kulaklar.
class SheepPainter extends AnimalPainter {
  const SheepPainter();

  static const _wool = Color(0xFFF4F1FA);
  static const _face = Color(0xFFD9C7B4);
  static const _ear = Color(0xFFC7B29C);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w * 0.5, h * 0.50);

    fillStroke(canvas, bumpyCircle(c, w * 0.38, 9, 0.12), _wool, w);

    // Kulaklar: yüzün iki yanından sarkar.
    for (final sign in [-1.0, 1.0]) {
      final ear = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(w * (0.5 + sign * 0.30), h * 0.585),
          width: w * 0.23,
          height: h * 0.135,
        ));
      fillStroke(canvas, ear, _ear, w, 0.8);
    }

    final face = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.615),
          width: w * 0.52,
          height: h * 0.46));
    fillStroke(canvas, face, _face, w);

    // Alnın üstünde yün perçemi — gözlerin üstünde kalır.
    fillStroke(
      canvas,
      bumpyCircle(Offset(w * 0.5, h * 0.375), w * 0.16, 5, 0.16),
      _wool,
      w,
      0.8,
    );

    final nose = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.695), width: w * 0.11, height: h * 0.07));
    canvas.drawPath(nose, Paint()..color = AnimalPainter.outline);
    drawSmile(canvas, w, Offset(w * 0.5, h * 0.735), w * 0.065);

    drawEye(canvas, Offset(w * 0.395, h * 0.575), w * 0.058);
    drawEye(canvas, Offset(w * 0.605, h * 0.575), w * 0.058);
    drawBlush(canvas, Offset(w * 0.315, h * 0.665), w * 0.05, h * 0.028);
    drawBlush(canvas, Offset(w * 0.685, h * 0.665), w * 0.05, h * 0.028);
  }
}

/// Tilki: sivri kulaklar, sivri çene, beyaz ağızlık.
class FoxPainter extends AnimalPainter {
  const FoxPainter();

  static const _fur = Color(0xFFE8813C);
  static const _furDark = Color(0xFFC96522);
  static const _muzzle = Color(0xFFFBF3EC);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    for (final sign in [-1.0, 1.0]) {
      final x = w * (0.5 + sign * 0.27);
      final ear = triangleEar(
        Offset(x - w * 0.10, h * 0.44),
        Offset(x + sign * w * 0.06, h * 0.10),
        Offset(x + w * 0.10, h * 0.42),
      );
      fillStroke(canvas, ear, _fur, w);
      canvas.drawPath(
        triangleEar(
          Offset(x - w * 0.05, h * 0.40),
          Offset(x + sign * w * 0.04, h * 0.19),
          Offset(x + w * 0.05, h * 0.39),
        ),
        Paint()..color = _furDark,
      );
    }

    // Yüz: geniş alın, sivri çene.
    final face = Path()
      ..moveTo(w * 0.5, h * 0.31)
      ..cubicTo(w * 0.86, h * 0.34, w * 0.84, h * 0.60, w * 0.66, h * 0.72)
      ..cubicTo(w * 0.58, h * 0.79, w * 0.54, h * 0.86, w * 0.5, h * 0.90)
      ..cubicTo(w * 0.46, h * 0.86, w * 0.42, h * 0.79, w * 0.34, h * 0.72)
      ..cubicTo(w * 0.16, h * 0.60, w * 0.14, h * 0.34, w * 0.5, h * 0.31)
      ..close();
    fillStroke(canvas, face, _fur, w);

    // Beyaz ağızlık.
    final muzzle = Path()
      ..moveTo(w * 0.5, h * 0.58)
      ..cubicTo(w * 0.66, h * 0.62, w * 0.60, h * 0.78, w * 0.5, h * 0.885)
      ..cubicTo(w * 0.40, h * 0.78, w * 0.34, h * 0.62, w * 0.5, h * 0.58)
      ..close();
    fillStroke(canvas, muzzle, _muzzle, w, 0.7);

    final nose = triangleEar(
      Offset(w * 0.455, h * 0.68),
      Offset(w * 0.5, h * 0.735),
      Offset(w * 0.545, h * 0.68),
    );
    canvas.drawPath(nose, Paint()..color = AnimalPainter.outline);

    drawEye(canvas, Offset(w * 0.37, h * 0.52), w * 0.058);
    drawEye(canvas, Offset(w * 0.63, h * 0.52), w * 0.058);
    drawBlush(canvas, Offset(w * 0.26, h * 0.60), w * 0.055, h * 0.03);
    drawBlush(canvas, Offset(w * 0.74, h * 0.60), w * 0.055, h * 0.03);
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
