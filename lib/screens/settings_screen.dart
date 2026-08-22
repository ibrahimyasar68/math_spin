import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/settings_store.dart';
import '../theme/app_colors.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/candy_button.dart';
import '../widgets/starry_background.dart';
import 'home_screen.dart';

/// Tema, ses ve avatar tercihlerinin yönetildiği ayarlar ekranı.
///
/// [onboarding] `true` iken uygulamanın ilk açılışıdır: geri butonu yerine altta
/// "HADİ BAŞLA" butonu gösterilir ve tamamlanınca ana ekrana geçilir.
class SettingsScreen extends StatelessWidget {
  final bool onboarding;

  const SettingsScreen({super.key, this.onboarding = false});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsStore.instance;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StarryBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                // Başlık satırı (normal modda geri butonu).
                Row(
                  children: [
                    if (!onboarding)
                      _RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      )
                    else
                      const SizedBox(width: 44),
                    Expanded(
                      child: Text(
                        onboarding ? 'Hoş geldin!' : 'Ayarlar',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.baloo2(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black38,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
                if (onboarding)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(
                      'Başlamadan önce tercihlerini seç',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tema seçimi.
                        _SettingsCard(
                          title: 'Tema',
                          icon: Icons.palette_rounded,
                          child: ValueListenableBuilder<ThemeMode>(
                            valueListenable: settings.themeMode,
                            builder: (context, mode, _) => Row(
                              children: [
                                _ThemeOption(
                                  label: 'Sistem',
                                  icon: Icons.brightness_auto_rounded,
                                  selected: mode == ThemeMode.system,
                                  onTap: () =>
                                      settings.setThemeMode(ThemeMode.system),
                                ),
                                const SizedBox(width: 10),
                                _ThemeOption(
                                  label: 'Açık',
                                  icon: Icons.wb_sunny_rounded,
                                  selected: mode == ThemeMode.light,
                                  onTap: () =>
                                      settings.setThemeMode(ThemeMode.light),
                                ),
                                const SizedBox(width: 10),
                                _ThemeOption(
                                  label: 'Koyu',
                                  icon: Icons.nightlight_round,
                                  selected: mode == ThemeMode.dark,
                                  onTap: () =>
                                      settings.setThemeMode(ThemeMode.dark),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Ses aç/kapa.
                        _SettingsCard(
                          title: 'Ses',
                          icon: Icons.volume_up_rounded,
                          child: ValueListenableBuilder<bool>(
                            valueListenable: settings.soundEnabled,
                            builder: (context, on, _) => Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    on ? 'Ses efektleri açık' : 'Ses kapalı',
                                    style: GoogleFonts.nunito(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: on,
                                  onChanged: settings.setSoundEnabled,
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: AppColors.success,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Avatar seçimi.
                        const _SettingsCard(
                          title: 'Avatar',
                          icon: Icons.face_rounded,
                          child: Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: AvatarPicker(showTitle: false),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // Onboarding'de başlangıç butonu.
                if (onboarding) ...[
                  CandyButton(
                    label: 'HADİ BAŞLA',
                    icon: Icons.play_arrow_rounded,
                    color: AppColors.success,
                    height: 68,
                    fontSize: 26,
                    onPressed: () async {
                      await settings.markOnboarded();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Başlıklı, yarı saydam ayar kartı.
class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.baloo2(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Tema seçenekleri için tek bir kart (Sistem / Açık / Koyu).
class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: selected ? 0.22 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.white : Colors.white24,
              width: selected ? 2.5 : 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.white70,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Başlık satırındaki yuvarlak ikon butonu (geri).
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
