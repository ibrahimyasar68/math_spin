import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/puzzle_image.dart';
import 'progress_store.dart';

/// Bulunulan kategorinin puzzle durumunu saklar: hangi resim atandı ve
/// hangi parçalar açıldı.
///
/// [ProgressStore] ile aynı kalıp: tekil örnek, [ValueNotifier] alanlar, her
/// değişiklikte diske yazma. Parça yalnızca matematik barajı geçilince açılır
/// ([ResultScreen] çağırır); kategori ise resim doğru tahmin edilince geçilir.
class PuzzleStore {
  PuzzleStore._();

  static final PuzzleStore instance = PuzzleStore._();

  /// Puzzle'ın parça adedi ve ızgara düzeni (5 satır × 2 sütun).
  static const int pieceCount = 10;
  static const int rows = 5;
  static const int cols = 2;

  static const String _kImage = 'puzzle.imageIndex';
  static const String _kMask = 'puzzle.revealedMask';

  /// Bu kategoriye atanmış resmin [puzzleImages] içindeki sırası.
  final ValueNotifier<int> imageIndex = ValueNotifier<int>(0);

  /// Açılmış parçaların bit maskesi (bit i = i. parça açık).
  final ValueNotifier<int> revealedMask = ValueNotifier<int>(0);

  final Random _rng = Random();
  bool _initialized = false;

  /// Bu kategorinin resmi.
  PuzzleImage get image => puzzleImages[imageIndex.value % puzzleImages.length];

  /// Açık parça sayısı.
  int get revealedCount {
    var n = 0;
    for (var i = 0; i < pieceCount; i++) {
      if (isRevealed(i)) n++;
    }
    return n;
  }

  bool isRevealed(int piece) => (revealedMask.value & (1 << piece)) != 0;

  /// Resmin tamamı açıldı mı? (Bu durumda yeni parça kazanılmaz.)
  bool get isComplete => revealedCount >= pieceCount;

  /// Kayıtlı durumu yükler ve kategori değişimlerini dinlemeye başlar.
  ///
  /// [ProgressStore.init] sonrasında çağrılmalı: dinleyici yalnızca sonraki
  /// değişimlerde tetiklenir, açılıştaki yükleme puzzle'ı sıfırlamaz.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      imageIndex.value =
          (prefs.getInt(_kImage) ?? _rng.nextInt(puzzleImages.length))
              .clamp(0, puzzleImages.length - 1);
      final mask = prefs.getInt(_kMask) ?? 0;
      revealedMask.value = mask & ((1 << pieceCount) - 1);
    } catch (e) {
      // Kayıt okunamazsa boş puzzle ile devam ederiz; oyun yine açılır.
      debugPrint('PuzzleStore init hatası: $e');
    }
    imageIndex.addListener(_persist);
    revealedMask.addListener(_persist);
    // Kategori hangi sebeple değişirse değişsin (geçiş ya da baştan başlama)
    // puzzle sıfırlanır; böylece sıfırlamayı çağırmayı unutabileceğimiz bir
    // yer kalmaz.
    ProgressStore.instance.category.addListener(resetForNewCategory);
  }

  /// Kapalı parçalardan rastgele birini açar.
  ///
  /// Açılan parçanın sırasını döndürür; açılacak parça kalmadıysa `null`.
  int? revealPiece({Random? rng}) {
    final closed = <int>[
      for (var i = 0; i < pieceCount; i++)
        if (!isRevealed(i)) i,
    ];
    if (closed.isEmpty) return null;
    final piece = closed[(rng ?? _rng).nextInt(closed.length)];
    revealedMask.value = revealedMask.value | (1 << piece);
    return piece;
  }

  /// Yeni kategoriye geçerken: parçalar kapanır, resim değişir.
  ///
  /// Yeni resim öncekiyle aynı olmaz — arka arkaya aynı hayvanı görmek hem
  /// tahmin gerilimini hem de sürprizi öldürürdü.
  void resetForNewCategory({Random? rng}) {
    revealedMask.value = 0;
    if (puzzleImages.length < 2) return;
    final r = rng ?? _rng;
    var next = imageIndex.value;
    while (next == imageIndex.value) {
      next = r.nextInt(puzzleImages.length);
    }
    imageIndex.value = next;
  }

  /// Yalnızca testler için: mağazayı bilinen bir duruma çeker.
  @visibleForTesting
  void debugSet({int? image, int? mask}) {
    if (image != null) imageIndex.value = image;
    if (mask != null) revealedMask.value = mask;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kImage, imageIndex.value);
      await prefs.setInt(_kMask, revealedMask.value);
    } catch (e) {
      debugPrint('Puzzle durumu kaydedilemedi: $e');
    }
  }
}
