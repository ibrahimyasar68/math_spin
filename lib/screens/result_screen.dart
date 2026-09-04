import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/question.dart';
import '../services/avatar_store.dart';
import '../services/progress_store.dart';
import '../services/puzzle_store.dart';
import '../theme/app_colors.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/mascot.dart';
import '../widgets/puzzle_panel.dart';
import '../widgets/starry_background.dart';
import 'cake_celebration_screen.dart';
import 'game_screen.dart';
import 'victory_screen.dart';

/// Kategori sonu özet ekranı.
///
/// Puan yüzde olarak hesaplanır (doğru / toplam × 100). Soru adedi kategoriye
/// göre değiştiği için (10'dan 5'e kadar) sabit "her doğru 10 puan" kuralı
/// kullanılamaz: 7 soruluk bir kategoride en fazla 70 puan çıkar ve baraj asla
/// geçilemezdi.
///
/// 80 puan ve üzeri **kategoriyi geçirmez**, bir puzzle parçası kazandırır;
/// kategori [PuzzleScreen] içinde resmi doğru tahmin edince geçilir.
class ResultScreen extends StatefulWidget {
  /// Oynanan kategori.
  final int category;

  final List<QuestionResult> results;

  const ResultScreen({
    super.key,
    required this.category,
    required this.results,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const int _passScore = 80;

  late final ConfettiController _confetti;

  int get _correct => widget.results.where((r) => r.correct).length;
  int get _total => widget.results.length;

  /// Yüzde puan: doğru / toplam × 100 (soru adedinden bağımsız 0–100).
  int get _score => _total == 0 ? 0 : (_correct * 100 / _total).round();

  bool get _passed => _score >= _passScore;

  bool get _isFinalCategory => widget.category >= ProgressStore.maxCategory;

  /// Bu turda açılan puzzle parçası (baraj geçilmediyse `null`).
  int? _newPiece;

  @override
  void initState() {
    super.initState();
    // Kategori artık burada geçilmez: geçiş, puzzle ekranındaki doğru tahminle
    // olur. Barajı geçmenin ödülü resimden rastgele bir parçanın açılması.
    if (_passed) {
      _newPiece = PuzzleStore.instance.revealPiece();
    }
    _confetti =
        ConfettiController(duration: const Duration(seconds: 3));
    // Kategori geçildiyse kutlama yağmuru.
    if (_passed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  ({String emoji, String message, MascotMood mood}) _feedback() {
    if (_total == 0) {
      return (emoji: '🙂', message: 'Hadi oynayalım!', mood: MascotMood.idle);
    }
    if (_passed && _isFinalCategory) {
      return (
        emoji: '🏆',
        message: 'Son kategoriyi geçtin! Resmi bilirsen oyun biter.',
        mood: MascotMood.happy,
      );
    }
    if (_passed) {
      return (
        emoji: '🧩',
        message: 'Harika! Bir puzzle parçası kazandın.',
        mood: MascotMood.happy,
      );
    }
    if (_score >= 50) {
      return (
        emoji: '💪',
        message: 'Az kaldı! Geçmek için 80 puan gerekli.',
        mood: MascotMood.thinking,
      );
    }
    return (
      emoji: '💪',
      message: 'Alıştırma yapalım, başarırsın!',
      mood: MascotMood.thinking,
    );
  }

  /// Final pastasındaki mum sayısı.
  ///
  /// Her kategori için bir mum koymak (20) üflemesi uzun sürdüğü ve küçük
  /// ekranda sıkıştığı için sabit tutuldu.
  static const int _finalCandles = 10;

  /// Yapbozdaki tahminin sonucu.
  ///
  /// Doğruysa kategori geçilir: son kategoride oyun biter (büyük pasta →
  /// şampiyonluk), değilse kategori bir artar ve mum üfleme kutlaması gelir.
  /// Yanlışsa oyuncu aynı kategoriden devam eder; açılmış parçalar durur.
  void _onGuessed(bool correct) {
    if (!mounted) return;

    if (!correct) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
      return;
    }

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

    final gecilen = widget.category; // geçilen kategori sayısı kadar mum
    ProgressStore.instance.setCategory(widget.category + 1);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CakeCelebrationScreen(
          candleCount: gecilen,
          nextBuilder: (_) => const GameScreen(),
        ),
      ),
    );
  }

  static Widget _buildVictory(BuildContext context) => const VictoryScreen();

  @override
  Widget build(BuildContext context) {
    final fb = _feedback();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StarryBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                // Yapboz artık ayrı bir ekran değil, bu ekranın gövdesinde:
                // oyun ile sonraki oyun arasında tek durak kalsın diye.
                // Maskot ve puan şeridi üstte küçültüldü, yer yapboza verildi.
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ValueListenableBuilder<int>(
                              valueListenable:
                                  AvatarStore.instance.selectedIndex,
                              builder: (context, idx, _) => Mascot(
                                mood: fb.mood,
                                skin: mascotSkins[idx],
                                size: 74,
                              ),
                            ),
                            Text(fb.emoji, style: const TextStyle(fontSize: 26)),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            fb.message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.baloo2(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ScoreBanner(
                      category: widget.category,
                      score: _score,
                      passed: _passed,
                    ),
                    const SizedBox(height: 8),
                    _ResultChips(results: widget.results),
                    const SizedBox(height: 10),
                    Expanded(
                      child: PuzzlePanel(
                        newPiece: _newPiece,
                        onGuessed: _onGuessed,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            // Tam puanda yıldız yağmuru hissi için yukarıdan konfeti.
            ConfettiOverlay(controller: _confetti),
          ],
        ),
      ),
    );
  }
}

/// Oynanan kategori ve alınan puanı gösteren şerit.
class _ScoreBanner extends StatelessWidget {
  final int category;
  final int score;
  final bool passed;

  const _ScoreBanner({
    required this.category,
    required this.score,
    required this.passed,
  });

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppColors.success : AppColors.sunny;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 2),
      ),
      // Dar ekranlarda / büyük yazı tiplerinde taşmasın diye küçülebilir.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: AppColors.sunny, size: 26),
            const SizedBox(width: 6),
            Text(
              'Kategori $category',
              style: GoogleFonts.baloo2(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 28),
            Text(
              '$score PUAN',
              style: GoogleFonts.baloo2(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soruların doğru/yanlış özeti: her soru için küçük numaralı bir rozet.
///
/// Eskiden burada kaydırmalı bir liste vardı; yapboz sonuç ekranına taşınınca
/// yer açmak gerekti. Aynı bilgi (hangi soru doğru, hangisi yanlış) tek bakışta
/// ve onda bir alanda duruyor.
class _ResultChips extends StatelessWidget {
  final List<QuestionResult> results;

  const _ResultChips({required this.results});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < results.length; i++)
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (results[i].correct ? AppColors.success : AppColors.danger)
                  .withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${i + 1}',
              style: GoogleFonts.baloo2(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
