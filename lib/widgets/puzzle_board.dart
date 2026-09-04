import 'dart:math';

import 'package:flutter/material.dart';

import '../models/puzzle_image.dart';
import '../services/puzzle_store.dart';
import 'animal_paintings.dart';

/// Yapboz tahtası: resmi [PuzzleStore.rows] × [PuzzleStore.cols] parçaya böler,
/// yalnızca açılmış olanları gösterir.
///
/// Parçalar düz dikdörtgen değil, **tırtıklı** gerçek yapboz parçalarıdır: iç
/// kenarlarda boyunlu bir çıkıntı ya da ona oturan bir girinti vardır. Komşu
/// iki parça aynı kenarı aynı eğriyle çizer (bkz. [_edge]), böylece aralarında
/// ne boşluk ne çakışma kalır.
///
/// Tahtanın tamamı **tek** [CustomPaint] ile çizilir: tırtıklar komşu hücreye
/// taştığı için parça başına ayrı bir kutu (Positioned + ClipRect) yetmezdi.
class PuzzleBoard extends StatelessWidget {
  final PuzzleImage image;

  /// Açık parçaların bit maskesi.
  final int revealedMask;

  /// Bu ekranda yeni açılan parça (varsa) — yerine büyüyerek oturur.
  final int? newPiece;

  const PuzzleBoard({
    super.key,
    required this.image,
    required this.revealedMask,
    this.newPiece,
  });

  @override
  Widget build(BuildContext context) {
    Widget board(double t) => CustomPaint(
          painter: _BoardPainter(
            image: image,
            revealedMask: revealedMask,
            newPiece: newPiece,
            entry: t,
          ),
          child: const SizedBox.expand(),
        );

    if (newPiece == null) return board(1);

    return TweenAnimationBuilder<double>(
      key: ValueKey(newPiece),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, t, _) => board(t),
    );
  }
}

/// [piece] numaralı yapboz parçasının yolu.
///
/// Tahtanın dışına açılır: parçaların birleşiminin tahtanın tamamını boşluksuz
/// ve çakışmasız kapladığını sınayan testler bunu kullanır.
Path puzzlePiecePath(String imageId, int piece, Size size) =>
    _PieceShapes.forImage(imageId, PuzzleStore.rows, PuzzleStore.cols)
        .pathFor(piece, size);

/// Bir yapboz parçasının kenar tırtıkları.
///
/// Kenar yönü **global** olarak saklanır (yatay kenarlar soldan sağa, dikey
/// kenarlar yukarıdan aşağı). Parça yolu saat yönünde çizildiği için alt ve sol
/// kenarlar ters yönde taranır; o iki kenarda yön çarpanı tersine çevrilir.
/// Eğrinin normali de ters döndüğü için sonuç aynı global eğri olur — komşu
/// parçalar birbirine tam oturur.
class _PieceShapes {
  final int rows;
  final int cols;

  /// Yatay iç kenarların yönü: `h[r][c]`, r. ve (r+1). satır arasındaki kenar.
  final List<List<int>> h;

  /// Dikey iç kenarların yönü: `v[r][c]`, c. ve (c+1). sütun arasındaki kenar.
  final List<List<int>> v;

  _PieceShapes._(this.rows, this.cols, this.h, this.v);

  /// Yönler resmin kimliğinden türer: aynı resim her açılışta aynı biçimde
  /// bölünür, farklı resimler farklı tırtıklara sahip olur.
  factory _PieceShapes.forImage(String id, int rows, int cols) {
    var seed = 7;
    for (final unit in id.codeUnits) {
      seed = (seed * 31 + unit) & 0x7fffffff;
    }
    final rng = Random(seed);
    int yon() => rng.nextBool() ? 1 : -1;
    return _PieceShapes._(
      rows,
      cols,
      [for (var r = 0; r < rows - 1; r++) [for (var c = 0; c < cols; c++) yon()]],
      [for (var r = 0; r < rows; r++) [for (var c = 0; c < cols - 1; c++) yon()]],
    );
  }

  /// [piece] numaralı parçanın kapalı yolu.
  Path pathFor(int piece, Size size) {
    final w = size.width / cols;
    final hgt = size.height / rows;
    final knob = 0.27 * min(w, hgt);
    final r = piece ~/ cols;
    final c = piece % cols;

    final tl = Offset(c * w, r * hgt);
    final tr = Offset((c + 1) * w, r * hgt);
    final br = Offset((c + 1) * w, (r + 1) * hgt);
    final bl = Offset(c * w, (r + 1) * hgt);

    // Dış kenarlarda tırtık yok (yön 0).
    final ust = r == 0 ? 0 : h[r - 1][c];
    final alt = r == rows - 1 ? 0 : h[r][c];
    final sol = c == 0 ? 0 : v[r][c - 1];
    final sag = c == cols - 1 ? 0 : v[r][c];

    final p = Path()..moveTo(tl.dx, tl.dy);
    _edge(p, tl, tr, ust, knob); // üst: soldan sağa (kanonik)
    _edge(p, tr, br, sag, knob); // sağ: yukarıdan aşağı (kanonik)
    _edge(p, br, bl, -alt, knob); // alt: sağdan sola (ters)
    _edge(p, bl, tl, -sol, knob); // sol: aşağıdan yukarı (ters)
    return p..close();
  }

  /// [a]'dan [b]'ye bir kenar çizer. [dir] 0 ise düz çizgi, değilse boyunlu bir
  /// çıkıntı/girinti.
  ///
  /// Tırtık biçimi t=0.5 ekseninde **simetriktir**; bu yüzden kenar ters yönde
  /// taransa da aynı eğri çıkar ve iki komşu parça bire bir örtüşür.
  static void _edge(Path p, Offset a, Offset b, int dir, double knob) {
    if (dir == 0) {
      p.lineTo(b.dx, b.dy);
      return;
    }
    final vec = b - a;
    final len = vec.distance;
    final d = vec / len;
    final n = Offset(-d.dy, d.dx) * (dir * knob);

    Offset at(double t, double o) => a + d * (t * len) + n * o;
    void cubic(Offset c1, Offset c2, Offset to) =>
        p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, to.dx, to.dy);

    final start = at(0.35, 0);
    p.lineTo(start.dx, start.dy);
    cubic(at(0.37, 0.18), at(0.30, 0.54), at(0.37, 0.72)); // boyun
    cubic(at(0.44, 1.00), at(0.56, 1.00), at(0.63, 0.72)); // baş
    cubic(at(0.70, 0.54), at(0.63, 0.18), at(0.65, 0.00)); // boyun
    p.lineTo(b.dx, b.dy);
  }
}

class _BoardPainter extends CustomPainter {
  final PuzzleImage image;
  final int revealedMask;
  final int? newPiece;

  /// Yeni parçanın yerine oturma ilerlemesi (0..1).
  final double entry;

  _BoardPainter({
    required this.image,
    required this.revealedMask,
    required this.newPiece,
    required this.entry,
  });

  bool _isRevealed(int piece) => (revealedMask & (1 << piece)) != 0;

  @override
  void paint(Canvas canvas, Size size) {
    final shapes = _PieceShapes.forImage(
      image.id,
      PuzzleStore.rows,
      PuzzleStore.cols,
    );
    final paths = [
      for (var i = 0; i < PuzzleStore.pieceCount; i++) shapes.pathFor(i, size),
    ];

    final kapaliDolgu = Paint()..color = Colors.white.withValues(alpha: 0.06);
    final kapaliKenar = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final acikKenar = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Önce kapalı yuvalar: açık parçalar üstlerine oturur.
    for (var i = 0; i < paths.length; i++) {
      if (_isRevealed(i)) continue;
      canvas.drawPath(paths[i], kapaliDolgu);
      canvas.drawPath(paths[i], kapaliKenar);
    }

    for (var i = 0; i < paths.length; i++) {
      if (!_isRevealed(i)) continue;
      final yeni = i == newPiece;
      canvas.save();
      if (yeni && entry < 1) {
        // Parça kendi merkezinden büyüyerek yerine oturur.
        final c = paths[i].getBounds().center;
        final s = 0.68 + 0.32 * entry;
        canvas.translate(c.dx, c.dy);
        canvas.scale(s, s);
        canvas.translate(-c.dx, -c.dy);
      }
      canvas.clipPath(paths[i]);
      AnimalBackdrop(image.backdrop).paint(canvas, size);
      image.painter().paint(canvas, size);
      canvas.restore();

      canvas.drawPath(paths[i], acikKenar);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) =>
      old.image.id != image.id ||
      old.revealedMask != revealedMask ||
      old.newPiece != newPiece ||
      old.entry != entry;
}
