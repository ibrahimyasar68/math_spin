import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/puzzle_image.dart';
import '../services/audio_service.dart';
import '../services/progress_store.dart';
import '../services/puzzle_store.dart';
import '../theme/app_colors.dart';
import '../widgets/candy_button.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/puzzle_board.dart';
import '../widgets/starry_background.dart';
import 'cake_celebration_screen.dart';
import 'game_screen.dart';
import 'victory_screen.dart';

/// Kategori sonundaki resim bilmecesi.
///
/// Kategoriye bir hayvan resmi atanır ve 10 parçaya bölünür. Matematik barajı
/// ([ResultScreen]) geçildiğinde rastgele bir parça açılır ve oyuncuya tahmin
/// hakkı verilir. **Doğru tahmin kategoriyi geçirir**; yanlışta oyuncu aynı
/// kategoride kalır ve açılan parçalar korunur.
///
/// Baraj geçilmediyse ekran yalnızca mevcut parçaları gösterir, şıklar kapalı
/// olur: tahmin hakkı matematikle kazanılır. Böylece rastgele şıkka basarak
/// matematiği atlamak mümkün olmaz.
class PuzzleScreen extends StatefulWidget {
  /// Az önce oynanan kategori.
  final int category;

  /// Bu turda baraj geçildi mi? Tahmin hakkı buna bağlı.
  final bool canGuess;

  /// Bu turda açılan parçanın sırası (yoksa `null`) — animasyonla girer.
  final int? newPiece;

  const PuzzleScreen({
    super.key,
    required this.category,
    required this.canGuess,
    this.newPiece,
  });

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late final ConfettiController _confetti;

  /// Şıkların sırası ekran ömrü boyunca sabit kalsın diye bir kez karılır.
  late final List<PuzzleImage> _choices;

  /// Seçilen şık (henüz seçilmediyse `null`).
  PuzzleImage? _picked;
  bool _navigating = false;

  bool get _isFinalCategory => widget.category >= ProgressStore.maxCategory;

  bool get _correct => _picked?.id == PuzzleStore.instance.image.id;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 1));
    _choices = List<PuzzleImage>.from(puzzleImages)..shuffle(Random());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _guess(PuzzleImage choice) {
    if (_picked != null || !widget.canGuess) return;
    setState(() => _picked = choice);

    if (_correct) {
      _confetti.play();
      AudioService.instance.playClap();
      _after(const Duration(milliseconds: 1500), _advance);
    } else {
      AudioService.instance.playWrong();
      _after(const Duration(milliseconds: 1500), _backToGame);
    }
  }

  void _after(Duration d, VoidCallback action) {
    Future.delayed(d, () {
      if (!mounted || _navigating) return;
      _navigating = true;
      action();
    });
  }

  /// Doğru tahmin: kategori geçilir.
  ///
  /// Son kategoriyse oyun biter (büyük pasta → şampiyonluk). Değilse kategori
  /// bir artar — [PuzzleStore] bu değişimi dinlediği için puzzle kendiliğinden
  /// sıfırlanır ve yeni resim atanır.
  void _advance() {
    if (_isFinalCategory) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const CakeCelebrationScreen(
            candleCount: _finalCandles,
            nextBuilder: _buildVictory,
          ),
        ),
      );
      return;
    }
    final passed = widget.category; // geçilen kategori sayısı kadar mum
    ProgressStore.instance.setCategory(widget.category + 1);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CakeCelebrationScreen(
          candleCount: passed,
          nextBuilder: (_) => const GameScreen(),
        ),
      ),
    );
  }

  void _backToGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  /// Final pastasındaki mum sayısı ([ResultScreen] ile aynı gerekçe).
  static const int _finalCandles = 10;

  static Widget _buildVictory(BuildContext context) => const VictoryScreen();

  // ---- Metinler ------------------------------------------------------------

  ({String title, String hint}) _copy(int revealed) {
    if (_picked != null) {
      return _correct
          ? (title: 'BİLDİN! 🎉', hint: 'Resim gerçekten ${_picked!.label}.')
          : (
              title: 'Bu değil 🙈',
              hint: 'Merak etme, parçaların duruyor. Yeni bir oyunla devam!',
            );
    }
    if (!widget.canGuess) {
      return (
        title: 'Parça kazanamadın',
        hint: 'Yeni parça ve tahmin hakkı için 80 puan gerekiyor.',
      );
    }
    if (revealed == PuzzleStore.pieceCount) {
      return (title: 'Resmin tamamı açık!', hint: 'Peki bu hangi hayvan?');
    }
    return (title: 'Yeni parça açıldı!', hint: 'Sence bu hangi hayvan?');
  }

  @override
  Widget build(BuildContext context) {
    final store = PuzzleStore.instance;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StarryBackground(
        child: Stack(
          children: [
            SafeArea(
              child: ValueListenableBuilder<int>(
                valueListenable: store.revealedMask,
                builder: (context, mask, _) {
                  final revealed = store.revealedCount;
                  final copy = _copy(revealed);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        Text(
                          copy.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.baloo2(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          copy.hint,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: PuzzleBoard(
                                image: store.image,
                                revealedMask: mask,
                                newPiece: widget.newPiece,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _PieceCounter(
                            revealed: revealed, total: PuzzleStore.pieceCount),
                        const SizedBox(height: 12),
                        if (widget.canGuess)
                          _Choices(
                            choices: _choices,
                            picked: _picked,
                            correctId: store.image.id,
                            onPick: _guess,
                          )
                        else
                          CandyButton(
                            label: 'TEKRAR DENE',
                            icon: Icons.refresh_rounded,
                            color: AppColors.sky,
                            height: 62,
                            fontSize: 22,
                            onPressed: _backToGame,
                          ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              ),
            ),
            ConfettiOverlay(controller: _confetti),
          ],
        ),
      ),
    );
  }
}

/// "3 / 10 parça" göstergesi.
class _PieceCounter extends StatelessWidget {
  final int revealed;
  final int total;

  const _PieceCounter({required this.revealed, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.extension_rounded,
              color: AppColors.accent, size: 20),
          const SizedBox(width: 8),
          Text(
            '$revealed / $total parça',
            style: GoogleFonts.baloo2(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tahmin şıkları.
///
/// Şıklar [puzzleImages] havuzundan gelir; havuza yeni hayvan eklendiğinde
/// buraya dokunmadan şık sayısı artar. Satır başına en fazla üç düğme konur,
/// fazlası alt satıra iner.
class _Choices extends StatelessWidget {
  final List<PuzzleImage> choices;
  final PuzzleImage? picked;
  final String correctId;
  final ValueChanged<PuzzleImage> onPick;

  const _Choices({
    required this.choices,
    required this.picked,
    required this.correctId,
    required this.onPick,
  });

  Color _colorFor(PuzzleImage c) {
    if (picked == null) return AppColors.grape;
    if (c.id == correctId) return AppColors.success;
    if (c.id == picked!.id) return AppColors.danger;
    return AppColors.grape;
  }

  @override
  Widget build(BuildContext context) {
    final perRow = choices.length <= 3 ? choices.length : 2;
    final rows = <List<PuzzleImage>>[];
    for (var i = 0; i < choices.length; i += perRow) {
      rows.add(choices.sublist(i, min(i + perRow, choices.length)));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows) ...[
          Row(
            children: [
              for (final c in row) ...[
                Expanded(
                  child: CandyButton(
                    label: c.label,
                    color: _colorFor(c),
                    height: 60,
                    fontSize: 20,
                    expand: false,
                    onPressed: picked == null ? () => onPick(c) : null,
                  ),
                ),
                if (c != row.last) const SizedBox(width: 10),
              ],
            ],
          ),
          if (row != rows.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
