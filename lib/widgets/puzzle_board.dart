import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/puzzle_image.dart';
import '../services/puzzle_store.dart';
import 'animal_paintings.dart';

/// Puzzle tahtası: resmi [PuzzleStore.rows] × [PuzzleStore.cols] ızgarada
/// gösterir, yalnızca açılmış parçaları çizer.
///
/// Her açık hücre **tam resmi** kendi köşesi kadar kaydırıp kırparak çizer;
/// böylece parçalar tek bir resmin dilimleri gibi kusursuz birleşir.
class PuzzleBoard extends StatelessWidget {
  final PuzzleImage image;

  /// Açık parçaların bit maskesi.
  final int revealedMask;

  /// Bu ekranda yeni açılan parça (varsa) — girişte kısa bir animasyonla gelir.
  final int? newPiece;

  const PuzzleBoard({
    super.key,
    required this.image,
    required this.revealedMask,
    this.newPiece,
  });

  static const _rows = PuzzleStore.rows;
  static const _cols = PuzzleStore.cols;
  static const _gap = 3.0;

  bool _isRevealed(int piece) => (revealedMask & (1 << piece)) != 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final cellW = side / _cols;
        final cellH = side / _rows;
        final full = Size(side, side);

        return SizedBox(
          width: side,
          height: side,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24, width: 2),
              color: Colors.black.withValues(alpha: 0.25),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  for (var piece = 0; piece < PuzzleStore.pieceCount; piece++)
                    Positioned(
                      left: (piece % _cols) * cellW,
                      top: (piece ~/ _cols) * cellH,
                      width: cellW,
                      height: cellH,
                      child: Padding(
                        padding: const EdgeInsets.all(_gap / 2),
                        child: _isRevealed(piece)
                            ? _RevealedPiece(
                                image: image,
                                full: full,
                                origin: Offset(
                                  (piece % _cols) * cellW,
                                  (piece ~/ _cols) * cellH,
                                ),
                                animate: piece == newPiece,
                              )
                            : const _ClosedPiece(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Açık parça: tam resmin kendi köşesine denk gelen dilimi.
class _RevealedPiece extends StatelessWidget {
  final PuzzleImage image;
  final Size full;
  final Offset origin;
  final bool animate;

  const _RevealedPiece({
    required this.image,
    required this.full,
    required this.origin,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final tile = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CustomPaint(
        painter: _PiecePainter(image: image, full: full, origin: origin),
        child: const SizedBox.expand(),
      ),
    );

    if (!animate) return tile;

    // Yeni kazanılan parça hafifçe büyüyerek yerine oturur.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(scale: 0.72 + 0.28 * t, child: child),
      ),
      child: tile,
    );
  }
}

/// Kapalı parça: soru işaretli koyu kart.
class _ClosedPiece extends StatelessWidget {
  const _ClosedPiece();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Center(
        child: Text(
          '?',
          style: GoogleFonts.baloo2(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.28),
          ),
        ),
      ),
    );
  }
}

/// Tam resmi çizip parçanın köşesine kaydıran ressam.
class _PiecePainter extends CustomPainter {
  final PuzzleImage image;
  final Size full;
  final Offset origin;

  _PiecePainter({
    required this.image,
    required this.full,
    required this.origin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(-origin.dx, -origin.dy);
    AnimalBackdrop(image.backdrop).paint(canvas, full);
    image.painter().paint(canvas, full);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PiecePainter oldDelegate) =>
      oldDelegate.image.id != image.id ||
      oldDelegate.origin != origin ||
      oldDelegate.full != full;
}
