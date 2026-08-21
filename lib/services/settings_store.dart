import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı ayarlarını (tema, ses, ilk-açılış durumu) kalıcı olarak saklar.
///
/// Basit [ValueNotifier] tabanlı singleton. Değerler her değişiklikte anında
/// diske yazılır; böylece uygulama kapatılıp açıldığında bu ayarlardan başlar.
class SettingsStore {
  SettingsStore._();

  static final SettingsStore instance = SettingsStore._();

  static const String _kTheme = 'settings.themeMode'; // 0=system 1=light 2=dark
  static const String _kSound = 'settings.soundEnabled';
  static const String _kOnboarded = 'settings.onboarded';

  /// Seçili tema modu (sistem / açık / koyu).
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  /// Ses efektleri açık mı?
  final ValueNotifier<bool> soundEnabled = ValueNotifier<bool>(true);

  /// Kullanıcı ilk açılış ayar ekranını tamamladı mı?
  bool onboarded = false;

  bool _initialized = false;

  /// Kayıtlı ayarları yükler ve sonraki değişiklikleri diske bağlar.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      themeMode.value = _intToMode(prefs.getInt(_kTheme) ?? 0);
      soundEnabled.value = prefs.getBool(_kSound) ?? true;
      onboarded = prefs.getBool(_kOnboarded) ?? false;
    } catch (e) {
      // Okuma başarısızsa varsayılanlarla devam ederiz; uygulama yine açılır.
      debugPrint('SettingsStore init hatası: $e');
    }
    themeMode.addListener(_persistTheme);
    soundEnabled.addListener(_persistSound);
  }

  void setThemeMode(ThemeMode mode) => themeMode.value = mode;

  void setSoundEnabled(bool value) => soundEnabled.value = value;

  /// İlk açılış ayar ekranı tamamlandığında çağrılır.
  Future<void> markOnboarded() async {
    onboarded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboarded, true);
    } catch (e) {
      debugPrint('Onboarded kaydedilemedi: $e');
    }
  }

  ThemeMode _intToMode(int v) => switch (v) {
        1 => ThemeMode.light,
        2 => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  int _modeToInt(ThemeMode m) => switch (m) {
        ThemeMode.light => 1,
        ThemeMode.dark => 2,
        ThemeMode.system => 0,
      };

  Future<void> _persistTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kTheme, _modeToInt(themeMode.value));
    } catch (e) {
      debugPrint('Tema kaydedilemedi: $e');
    }
  }

  Future<void> _persistSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSound, soundEnabled.value);
    } catch (e) {
      debugPrint('Ses ayarı kaydedilemedi: $e');
    }
  }
}
