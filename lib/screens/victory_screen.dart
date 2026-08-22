import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/audio_service.dart';
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
/// Şampiyonluk başlığı sırayla belirir, yolculuk özeti ve ödül avatarının
/// kilidinin açıldığı kart gösterilir. Oyuncu buradan baştan başlayabilir ya da
/// son kategoride kalmaya devam edebilir.
class VictoryScreen extends StatefulWidget {
  const VictoryScreen({super.key});

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  late final ConfettiController _confetti;

  /// Oyuncu bu ekrana gelmeden önce ödülü zaten kazanmış mıydı?
  ///
  /// İlk bitirişte "kilidi açıldı" vurgusu yapılır; tekrar bitirişlerde ödül
  /// yalnızca hatırlatılır.
  late final bool _firstTime;

  @override
  void initState() {
    super.initState();
    _firstTime = !ProgressStore.instance.completed.value;
    // Rozet ve ödül avatarı kalıcı olarak açılır.
    ProgressStore.instance.markCompleted();

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
          'İlerlemen Kategori 1\'e döner. Şampiyon rozetin ve ödül avatarın '
          'sende kalır.',
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
                        // Taçlı şampiyon maskotu.
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
                            'ŞAMPİYON!',
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
                            'Tüm kategorileri bitirdin!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Yolculuk özeti.
                        Opacity(
                          opacity: statsIn,
                          child: Transform.translate(
                            offset: Offset(0, (1 - statsIn) * 14),
                            child: const _JourneySummary(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Ödül avatarı.
                        Opacity(
                          opacity: rewardIn.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: (0.7 + rewardIn * 0.3).clamp(0.7, 1.05),
                            child: _RewardCard(firstTime: _firstTime),
                          ),
                        ),
                        const Spacer(),
                        Opacity(
                          opacity: buttonsIn,
                          child: Column(
                            children: [
                              CandyButton(
                                label: 'BAŞTAN BAŞLA',
                                icon: Icons.restart_alt_rounded,
                                color: AppColors.success,
                                height: 64,
                                fontSize: 24,
                                onPressed: _confirmRestart,
                              ),
                              const SizedBox(height: 10),
                              CandyButton(
                                label: 'SON KATEGORİYİ OYNA',
                                icon: Icons.replay_rounded,
                                color: AppColors.sky,
                                height: 58,
                                fontSize: 21,
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
            child: Mascot(
              mood: MascotMood.happy,
              skin: mascotSkins[championSkinIndex],
              size: 130,
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

/// Kilidi açılan ödül avatarını tanıtan kart.
class _RewardCard extends StatelessWidget {
  final bool firstTime;

  const _RewardCard({required this.firstTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          Mascot(
            mood: MascotMood.happy,
            skin: mascotSkins[championSkinIndex],
            size: 56,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  firstTime ? '🔓 Yeni avatar açıldı!' : '🏆 Ödül avatarın',
                  style: GoogleFonts.baloo2(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Şampiyon avatarını ayarlardan seçebilirsin.',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
