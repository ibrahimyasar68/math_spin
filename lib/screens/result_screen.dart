import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/question.dart';
import '../services/avatar_store.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import '../widgets/candy_button.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/mascot.dart';
import '../widgets/starry_background.dart';
import 'cake_celebration_screen.dart';
import 'game_screen.dart';
import 'victory_screen.dart';

/// Kategori sonu özet ekranı.
///
/// Puan yüzde olarak hesaplanır (doğru / toplam × 100); 80 puan ve üzeri bir
/// üst kategoriye geçirir. Soru adedi kategoriye göre değiştiği için (10'dan
/// 5'e kadar) sabit "her doğru 10 puan" kuralı kullanılamaz: 7 soruluk bir
/// kategoride en fazla 70 puan çıkar ve baraj asla geçilemezdi.
/// Geçiş burada [ProgressStore]'a yazılır.
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
  int get _wrong => widget.results.length - _correct;
  int get _total => widget.results.length;

  /// Yüzde puan: doğru / toplam × 100 (soru adedinden bağımsız 0–100).
  int get _score => _total == 0 ? 0 : (_correct * 100 / _total).round();

  bool get _passed => _score >= _passScore;

  bool get _isFinalCategory => widget.category >= ProgressStore.maxCategory;

  @override
  void initState() {
    super.initState();
    // Barajı geçen oyuncu bir üst kategoriye taşınır ve kaydedilir.
    if (_passed && !_isFinalCategory) {
      ProgressStore.instance.setCategory(widget.category + 1);
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
        message: 'Şampiyon! Tüm kategorileri bitirdin!',
        mood: MascotMood.happy,
      );
    }
    if (_passed) {
      return (
        emoji: '🎉',
        message: 'Tebrikler! Kategori ${widget.category + 1}\'e geçtin!',
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
  /// Her kategori için bir mum koymak (40) üflemesi uzun sürdüğü ve küçük
  /// ekranda sıkıştığı için sabit tutuldu.
  static const int _finalCandles = 10;

  /// Buton her zaman güncel (kayıtlı) kategoriden yeni oyun başlatır:
  /// geçildiyse üst kategori, geçilemediyse aynı kategori.
  ///
  /// Bir üst kategoriye geçişte önce yaş pasta kutlaması gösterilir: oyuncu
  /// o ana kadar geçtiği kategori sayısı kadar mumu üfleyip söndürünce oyuna
  /// devam edilir.
  ///
  /// Son kategori geçildiyse oyun biter: büyük pastanın ardından şampiyonluk
  /// ekranı gelir.
  void _playAgain() {
    if (_passed && _isFinalCategory) {
      // Oyun bitti: doruk noktası olarak büyük pasta, sonra final ekranı.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const CakeCelebrationScreen(
            candleCount: _finalCandles,
            nextBuilder: _buildVictory,
          ),
        ),
      );
    } else if (_passed) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CakeCelebrationScreen(
            candleCount: widget.category, // geçilen kategori sayısı kadar mum
            nextBuilder: (_) => const GameScreen(),
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    }
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
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ValueListenableBuilder<int>(
                          valueListenable: AvatarStore.instance.selectedIndex,
                          builder: (context, idx, _) => Mascot(
                            mood: fb.mood,
                            skin: mascotSkins[idx],
                            size: 110,
                          ),
                        ),
                        Text(fb.emoji, style: const TextStyle(fontSize: 40)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fb.message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.baloo2(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ScoreBanner(
                      category: widget.category,
                      score: _score,
                      passed: _passed,
                    ),
                    const SizedBox(height: 12),
                    _ScoreCards(correct: _correct, wrong: _wrong, total: _total),
                    const SizedBox(height: 16),
                    Expanded(child: _SummaryList(results: widget.results)),
                    const SizedBox(height: 12),
                    CandyButton(
                      label: _passed
                          ? (_isFinalCategory
                              ? 'OYUNU BİTİR'
                              : 'SONRAKİ KATEGORİ')
                          : 'TEKRAR DENE',
                      icon: _passed
                          ? Icons.arrow_forward_rounded
                          : Icons.refresh_rounded,
                      color: AppColors.success,
                      height: 68,
                      fontSize: 26,
                      onPressed: _playAgain,
                    ),
                    const SizedBox(height: 16),
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

class _ScoreCards extends StatelessWidget {
  final int correct;
  final int wrong;
  final int total;

  const _ScoreCards({
    required this.correct,
    required this.wrong,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: 'Doğru',
          value: '$correct',
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Yanlış',
          value: '$wrong',
          color: AppColors.danger,
          icon: Icons.cancel_rounded,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Toplam',
          value: '$total',
          color: AppColors.sky,
          icon: Icons.functions_rounded,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.baloo2(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryList extends StatelessWidget {
  final List<QuestionResult> results;

  const _SummaryList({required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 4),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final r = results[i];
        final color = r.correct ? AppColors.success : AppColors.danger;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color,
                child: Text(
                  '${i + 1}',
                  style: GoogleFonts.baloo2(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dört basamaklı sayılarla uzayan işlem satırı taşmasın.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        r.question.solvedPrompt,
                        maxLines: 1,
                        softWrap: false,
                        style: GoogleFonts.baloo2(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!r.correct)
                      Text(
                        r.givenAnswer == null
                            ? 'Cevaplanmadı'
                            : 'Senin cevabın: ${r.givenAnswer}',
                        style: GoogleFonts.nunito(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                r.correct ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 30,
              ),
            ],
          ),
        );
      },
    );
  }
}
