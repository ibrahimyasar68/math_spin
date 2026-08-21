import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'avatar_store.dart';

/// Oyuncunun kalıcı ilerlemesini (kategori + avatar tercihi) saklar.
///
/// Kategori 1'den başlar, [maxCategory] ile sınırlıdır. Değerler her
/// değişiklikte anında diske yazılır; böylece uygulama nasıl kapanırsa
/// kapansın oyuncu kaldığı yerden devam eder.
class ProgressStore {
  ProgressStore._();

  static final ProgressStore instance = ProgressStore._();

  static const int maxCategory = 50;
  static const String _kCategory = 'player.category';
  static const String _kAvatar = 'player.avatarIndex';

  /// Oyuncunun şu an bulunduğu kategori (1..[maxCategory]).
  final ValueNotifier<int> category = ValueNotifier<int>(1);

  bool _initialized = false;

  /// Kayıtlı ilerlemeyi yükler ve sonraki değişiklikleri diske bağlar.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      category.value = (prefs.getInt(_kCategory) ?? 1).clamp(1, maxCategory);
      final avatar = prefs.getInt(_kAvatar);
      if (avatar != null) AvatarStore.instance.select(avatar);
    } catch (e) {
      // Kayıt okunamazsa varsayılanlarla devam ederiz; oyun yine açılır.
      debugPrint('ProgressStore init hatası: $e');
    }
    category.addListener(_persistCategory);
    AvatarStore.instance.selectedIndex.addListener(_persistAvatar);
  }

  /// Kategoriyi 1..[maxCategory] aralığına sıkıştırarak günceller.
  void setCategory(int value) {
    category.value = value.clamp(1, maxCategory);
  }

  Future<void> _persistCategory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kCategory, category.value);
    } catch (e) {
      debugPrint('Kategori kaydedilemedi: $e');
    }
  }

  Future<void> _persistAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kAvatar, AvatarStore.instance.selectedIndex.value);
    } catch (e) {
      debugPrint('Avatar kaydedilemedi: $e');
    }
  }
}
