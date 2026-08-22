import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/audio_service.dart';
import '../services/avatar_store.dart';
import '../services/progress_store.dart';
import '../services/question_generator.dart';
import '../theme/app_colors.dart';
import '../widgets/candy_button.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/mascot.dart';
import '../widgets/starry_background.dart';
import 'game_screen.dart';
import 'home_screen.dart';

/// Oyunun bitirildiği (son kategori geçildiği) final ekranı.
///
/// Her bitiriş bir yıldız kazandırır; yıldızlar ana ekranda avatarın iki
/// yanında gösterilir. [ProgressStore.maxStars] tamamlandığında oyun tamamen
/// biter ve baştan başlama sunulmaz.
class VictoryScreen extends StatefulWidget {
  const VictoryScreen({super.key});

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  late final ConfettiController _confetti;

  /// Bu bitirişle ulaşılan yıldız sayısı.
  late final int _stars;

  /// Tüm yıldızlar toplandı mı? Toplandıysa oyun tamamen biter: baştan başlama
  /// sunulmaz.
  bool get _fullyComplete => _stars >= ProgressStore.maxStars;

  @override
  void initState() {
    super.initState();
    // Bu bitiriş bir yıldız kazandırır; yıldızlar kalıcıdır.
    ProgressStore.instance.awardStar();
    _stars = ProgressStore.instance.stars.value;

    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
      AudioService.instance.playClap();
    });
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _confetti.dispose();
    super.dispose();
  }

  /// [start]–[end] aralığında 0→1 ilerleyen, [c] ile yumuşatılmış değer.
  double _seg(double start, double end, [Curve c = Curves.easeOut]) {
    final t = ((_intro.value - start) / (end - start)).clamp(0.0, 1.0);
    return c.transform(t);
  }

  /// Baştan başlamadan önce onay ister: ilerleme sıfırlanacak.
  Future<void> _confirmRestart() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Baştan başlansın mı?',
          style: GoogleFonts.baloo2(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: Text(
          'İlerlemen Kategori 1\'e döner. Kazandığın yıldızlar sende kalır.',
          style: GoogleFonts.nunito(fontSize: 17, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Vazgeç',
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Baştan başla',
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    ProgressStore.instance.restart();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  /// Son kategoride kalmaya devam eder.
  void _replayFinal() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StarryBackground(
        child: Stack(
          children: [
            SafeArea(
              child: AnimatedBuilder(
                animation: _intro,
                builder: (context, _) {
                  final mascotIn = _seg(0.0, 0.45, Curves.easeOutBack);
                  final titleIn = _seg(0.2, 0.6);
                  final statsIn = _seg(0.45, 0.8);
                  final rewardIn = _seg(0.6, 0.95, Curves.easeOutBack);
                  final buttonsIn = _seg(0.75, 1.0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Spacer(),
                        // Taçlı maskot (oyuncunun seçtiği avatar).
                        Opacity(
                          opacity: mascotIn.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: (0.4 + mascotIn * 0.6).clamp(0.4, 1.0),
                            child: const _CrownedMascot(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Başlık: harf aralığı toplanarak belirir.
                        Opacity(
                          opacity: titleIn,
                          child: Text(
                            _fullyComplete ? 'OYUN BİTTİ!' : 'ŞAMPİYON!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.baloo2(
                              fontSize: 46,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                              letterSpacing: (1 - titleIn) * 16 + 1,
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Opacity(
                          opacity: titleIn,
                          child: Text(
                            _fullyComplete
                                ? 'Tüm yıldızları topladın!\nOyunu tamamen '
                                    'bitirdin.'
                                : 'Tüm kategorileri bitirdin!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Kazanılan yıldızlar.
                        Opacity(
                          opacity: rewardIn.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: (0.7 + rewardIn * 0.3).clamp(0.7, 1.05),
                            child: _StarBoard(stars: _stars),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Yolculuk özeti.
                        Opacity(
                          opacity: statsIn,
                          child: Transform.translate(
                            offset: Offset(0, (1 - statsIn) * 14),
                            child: const _JourneySummary(),
                          ),
                        ),
                        const Spacer(),
                        Opacity(
                          opacity: buttonsIn,
                          child: Column(
                            children: [
                              // Oyun tamamen bittiyse baştan başlama sunulmaz.
                              if (!_fullyComplete) ...[
                                CandyButton(
                                  label: 'BAŞTAN BAŞLA',
                                  icon: Icons.restart_alt_rounded,
                                  color: AppColors.success,
                                  height: 64,
                                  fontSize: 24,
                                  onPressed: _confirmRestart,
                                ),
                                const SizedBox(height: 10),
                              ],
                              CandyButton(
                                label: 'SON KATEGORİYİ OYNA',
                                icon: Icons.replay_rounded,
                                color: _fullyComplete
                                    ? AppColors.success
                                    : AppColors.sky,
                                height: _fullyComplete ? 64 : 58,
                                fontSize: _fullyComplete ? 24 : 21,
                                onPressed: _replayFinal,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
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

/// Şampiyon avatarı + üstünde taç.
class _CrownedMascot extends StatelessWidget {
  const _CrownedMascot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: ValueListenableBuilder<int>(
              valueListenable: AvatarStore.instance.selectedIndex,
              builder: (context, idx, _) => Mascot(
                mood: MascotMood.happy,
                skin: mascotSkins[idx],
                size: 130,
              ),
            ),
          ),
          const Positioned(
            top: -10,
            child: Text('👑', style: TextStyle(fontSize: 44)),
          ),
        ],
      ),
    );
  }
}

/// Tamamlanan yolculuğun özeti.
class _JourneySummary extends StatelessWidget {
  const _JourneySummary();

  @override
  Widget build(BuildContext context) {
    var questions = 0;
    for (var c = 1; c <= QuestionGenerator.maxCategory; c++) {
      questions += QuestionGenerator.questionCountFor(c);
    }

    Widget item(IconData icon, String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 26),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.baloo2(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Row(
        children: [
          item(Icons.emoji_events_rounded, '${QuestionGenerator.maxCategory}',
              'kategori'),
          item(Icons.calculate_rounded, '$questions', 'soru'),
          item(Icons.auto_awesome_rounded, '4', 'basamak'),
        ],
      ),
    );
  }
}

/// Kazanılan yıldızları gösteren tablo.
///
/// Ana ekrandaki dizilimle aynı mantık: yıldızlar avatarın iki yanına dengeli
/// dağılır, [ProgressStore.maxStars] tamamlanınca 5 sağda 5 solda olur. Burada
/// ise tek sırada, kazanılmayanlar soluk gösterilir.
class _StarBoard extends StatelessWidget {
  final int stars;

  const _StarBoard({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < ProgressStore.maxStars; i++)
                  Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i < stars
                        ? AppColors.sunny
                        : Colors.white.withValues(alpha: 0.35),
                    size: 28,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$stars / ${ProgressStore.maxStars} yıldız',
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
