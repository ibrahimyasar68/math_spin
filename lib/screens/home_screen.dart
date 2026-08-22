import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/avatar_store.dart';
import '../services/progress_store.dart';
import '../theme/app_colors.dart';
import '../widgets/candy_button.dart';
import '../widgets/mascot.dart';
import '../widgets/starry_background.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

/// Açılış / ana menü ekranı.
///
/// "Kozmik Zoom" giriş efekti: ortadan genişleyen ışık halkası eşliğinde maskot
/// uzaktan dönerek yakınlaşır, başlık harf aralığı toplanarak belirir, alt yazı
/// ve buton sırayla yükselir. Animasyon bitince avatar seçici belirir.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  bool _introDone = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _introDone = true);
      }
    });
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// [start]–[end] aralığında 0→1 ilerleyen, [c] eğrisiyle yumuşatılmış değer.
  double _seg(double start, double end, [Curve c = Curves.easeOut]) {
    final t = ((_intro.value - start) / (end - start)).clamp(0.0, 1.0);
    return c.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StarryBackground(
        child: SafeArea(
          child: Stack(
            children: [
              _buildContent(),
              // Sağ üstte ayarlara erişim.
              Positioned(
                top: 4,
                right: 4,
                child: AnimatedOpacity(
                  opacity: _introDone ? 1 : 0,
                  duration: const Duration(milliseconds: 450),
                  child: IgnorePointer(
                    ignoring: !_introDone,
                    child: _SettingsButton(onTap: _openSettings),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
            animation: _intro,
            builder: (context, _) {
              final mv = _seg(0.0, 0.5, Curves.easeOutBack);
              final wv = _seg(0.0, 0.5);
              final tv = _seg(0.225, 0.675);
              final sv = _seg(0.475, 0.775);
              final bDy = _seg(0.575, 0.925, Curves.elasticOut);
              final bo = _seg(0.575, 0.8);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Maskot + arkasında genişleyen ışık halkası (warp).
                    SizedBox(
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: (1 - wv) * 0.8,
                            child: Transform.scale(
                              scale: wv * 4.5,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.accent,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: mv.clamp(0.0, 1.0),
                            child: Transform.rotate(
                              angle: (1 - mv) * -0.9,
                              child: Transform.scale(
                                scale: (0.05 + mv * 0.95).clamp(0.05, 1.15),
                                child: ValueListenableBuilder<int>(
                                  valueListenable:
                                      AvatarStore.instance.selectedIndex,
                                  builder: (context, idx, __) => Mascot(
                                    mood: MascotMood.happy,
                                    skin: mascotSkins[idx],
                                    size: 140,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Başlık: harf aralığı toplanarak belirir.
                    Opacity(
                      opacity: tv,
                      child: Text(
                        'MathSpin',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.baloo2(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: (1 - tv) * 20 + 0.5,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: sv,
                      child: Transform.translate(
                        offset: Offset(0, (1 - sv) * 12),
                        child: Text(
                          'Çarkı çevir, matematiği çöz!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Oyuncunun kaldığı kategori (kalıcı ilerleme).
                    Opacity(
                      opacity: sv,
                      child: ValueListenableBuilder<int>(
                        valueListenable: ProgressStore.instance.category,
                        builder: (context, cat, _) =>
                            _CategoryBadge(category: cat),
                      ),
                    ),
                    const Spacer(),
                    Opacity(
                      opacity: bo,
                      child: Transform.translate(
                        offset: Offset(0, (1 - bDy) * 52),
                        child: CandyButton(
                          label: 'BAŞLA',
                          icon: Icons.play_arrow_rounded,
                          color: AppColors.success,
                          height: 72,
                          fontSize: 28,
                          onPressed: _introDone ? _startGame : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '10 yaş altı çocuklar için',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
  }

  void _startGame() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }
}

/// Sağ üstteki yuvarlak ayarlar (dişli) butonu.
class _SettingsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SettingsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38, width: 1.5),
        ),
        child: const Icon(Icons.settings_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}

/// Ana ekranda oyuncunun bulunduğu kategoriyi gösteren rozet.
class _CategoryBadge extends StatelessWidget {
  final int category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grape.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.9),
          width: 2,
        ),
      ),
      // Dar ekranlarda / büyük yazı tiplerinde taşmasın diye küçülebilir.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: AppColors.sunny, size: 22),
            const SizedBox(width: 8),
            Text(
              'Kategori $category',
              style: GoogleFonts.baloo2(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
