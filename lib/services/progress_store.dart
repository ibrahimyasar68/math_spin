import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/mascot.dart';
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
  static const String _kCompleted = 'player.completed';

  /// Oyuncunun şu an bulunduğu kategori (1..[maxCategory]).
  final ValueNotifier<int> category = ValueNotifier<int>(1);

  /// Oyuncu oyunu (son kategoriyi) en az bir kez bitirdi mi?
  ///
  /// Bir kez `true` olunca kalıcıdır: baştan başlansa bile şampiyon rozeti ve
  /// ödül avatarı açık kalır.
  final ValueNotifier<bool> completed = ValueNotifier<bool>(false);

  bool _initialized = false;

  /// Kayıtlı ilerlemeyi yükler ve sonraki değişiklikleri diske bağlar.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      category.value = (prefs.getInt(_kCategory) ?? 1).clamp(1, maxCategory);
      completed.value = prefs.getBool(_kCompleted) ?? false;
      final avatar = prefs.getInt(_kAvatar);
      // Ödül avatarı kilitliyken seçili kalmasın (ör. kayıt elle düzenlenirse).
      if (avatar != null &&
          (avatar != championSkinIndex || completed.value)) {
        AvatarStore.instance.select(avatar);
      }
    } catch (e) {
      // Kayıt okunamazsa varsayılanlarla devam ederiz; oyun yine açılır.
      debugPrint('ProgressStore init hatası: $e');
    }
    category.addListener(_persistCategory);
    completed.addListener(_persistCompleted);
    AvatarStore.instance.selectedIndex.addListener(_persistAvatar);
  }

  /// Kategoriyi 1..[maxCategory] aralığına sıkıştırarak günceller.
  void setCategory(int value) {
    category.value = value.clamp(1, maxCategory);
  }

  /// Son kategori bitirildiğinde çağrılır: şampiyon rozetini ve ödül avatarını
  /// kalıcı olarak açar.
  void markCompleted() => completed.value = true;

  /// İlerlemeyi baştan başlatır. [completed] bilinçli olarak korunur; şampiyon
  /// rozeti ve ödül avatarı bir kez kazanılınca geri alınmaz.
  void restart() => setCategory(1);

  Future<void> _persistCategory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kCategory, category.value);
    } catch (e) {
      debugPrint('Kategori kaydedilemedi: $e');
    }
  }

  Future<void> _persistCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kCompleted, completed.value);
    } catch (e) {
      debugPrint('Bitirme durumu kaydedilemedi: $e');
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
