import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'avatar_store.dart';
import 'question_generator.dart';

/// Oyuncunun kalıcı ilerlemesini (kategori + avatar tercihi) saklar.
///
/// Kategori 1'den başlar, [maxCategory] ile sınırlıdır. Değerler her
/// değişiklikte anında diske yazılır; böylece uygulama nasıl kapanırsa
/// kapansın oyuncu kaldığı yerden devam eder.
class ProgressStore {
  ProgressStore._();

  static final ProgressStore instance = ProgressStore._();

  /// Son kategori. Tek kaynak [QuestionGenerator]'dır; bant düzeni değişince
  /// buradaki sınır da kendiliğinden uyar.
  static const int maxCategory = QuestionGenerator.maxCategory;
  static const String _kCategory = 'player.category';
  static const String _kAvatar = 'player.avatarIndex';
  static const String _kStars = 'player.stars';

  /// Eski sürümün "bitirdi mi" bayrağı; [_kStars] yokken 1 yıldıza çevrilir.
  static const String _kLegacyCompleted = 'player.completed';

  /// Oyunun tamamen bitmesi için gereken yıldız: avatarın 5 sağında,
  /// 5 solunda.
  static const int maxStars = 10;

  /// Oyuncunun şu an bulunduğu kategori (1..[maxCategory]).
  final ValueNotifier<int> category = ValueNotifier<int>(1);

  /// Tüm kategorilerin kaç kez bitirildiği (0..[maxStars]).
  ///
  /// Her bitiriş bir yıldız kazandırır; yıldızlar ana ekranda avatarın iki
  /// yanında gösterilir ve baştan başlansa bile korunur.
  final ValueNotifier<int> stars = ValueNotifier<int>(0);

  /// Oyun en az bir kez bitirildi mi?
  bool get hasFinishedOnce => stars.value > 0;

  /// Tüm yıldızlar toplandı mı? (oyun tamamen bitti)
  bool get isFullyComplete => stars.value >= maxStars;

  bool _initialized = false;

  /// Kayıtlı ilerlemeyi yükler ve sonraki değişiklikleri diske bağlar.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      category.value = (prefs.getInt(_kCategory) ?? 1).clamp(1, maxCategory);
      // Eski kayıtlarda yıldız yoktu; "bitirdi" bayrağı 1 yıldıza çevrilir.
      final saved = prefs.getInt(_kStars) ??
          ((prefs.getBool(_kLegacyCompleted) ?? false) ? 1 : 0);
      stars.value = saved.clamp(0, maxStars);
      final avatar = prefs.getInt(_kAvatar);
      if (avatar != null) AvatarStore.instance.select(avatar);
    } catch (e) {
      // Kayıt okunamazsa varsayılanlarla devam ederiz; oyun yine açılır.
      debugPrint('ProgressStore init hatası: $e');
    }
    category.addListener(_persistCategory);
    stars.addListener(_persistStars);
    AvatarStore.instance.selectedIndex.addListener(_persistAvatar);
  }

  /// Kategoriyi 1..[maxCategory] aralığına sıkıştırarak günceller.
  void setCategory(int value) {
    category.value = value.clamp(1, maxCategory);
  }

  /// Son kategori bitirildiğinde çağrılır: bir yıldız kazandırır.
  ///
  /// [maxStars] sınırına ulaşıldığında artık yıldız eklenmez.
  void awardStar() {
    if (stars.value < maxStars) stars.value = stars.value + 1;
  }

  /// İlerlemeyi baştan başlatır. Yıldızlar bilinçli olarak korunur; bir kez
  /// kazanılan yıldız geri alınmaz.
  void restart() => setCategory(1);

  Future<void> _persistCategory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kCategory, category.value);
    } catch (e) {
      debugPrint('Kategori kaydedilemedi: $e');
    }
  }

  Future<void> _persistStars() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kStars, stars.value);
    } catch (e) {
      debugPrint('Yıldızlar kaydedilemedi: $e');
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
