import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathspin/models/puzzle_image.dart';
import 'package:mathspin/services/progress_store.dart';
import 'package:mathspin/services/puzzle_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final store = PuzzleStore.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store.debugSet(image: 0, mask: 0);
  });

  test('Parça açma hep kapalı bir parça seçer ve 10 parçada doyar', () {
    final acilanlar = <int>[];

    for (var i = 0; i < PuzzleStore.pieceCount; i++) {
      final piece = store.revealPiece(rng: Random(i));
      expect(piece, isNotNull, reason: '${i + 1}. parça açılabilmeli');
      expect(acilanlar, isNot(contains(piece)),
          reason: 'Aynı parça iki kez açılmamalı');
      acilanlar.add(piece!);
      expect(store.isRevealed(piece), isTrue);
      expect(store.revealedCount, i + 1);
    }

    expect(store.isComplete, isTrue);
    expect(store.revealPiece(), isNull,
        reason: 'Tüm parçalar açıkken yeni parça açılmamalı');
    expect(store.revealedCount, PuzzleStore.pieceCount,
        reason: 'Doyduktan sonra sayaç artmamalı');
  });

  test('Açılan parça rastgele seçilir (hep aynı sırayla gelmez)', () {
    List<int> sequence(int seed) {
      store.debugSet(mask: 0);
      final rng = Random(seed);
      return [
        for (var i = 0; i < 4; i++) store.revealPiece(rng: rng)!,
      ];
    }

    // Farklı tohumlar farklı açılış sırası vermeli; aksi hâlde seçim
    // rastgele değil demektir.
    expect(sequence(1), isNot(equals(sequence(9))));
  });

  test('Yeni kategoriye geçince parçalar kapanır ve resim değişir', () {
    store.revealPiece(rng: Random(3));
    store.revealPiece(rng: Random(4));
    expect(store.revealedCount, 2);
    final onceki = store.imageIndex.value;

    store.resetForNewCategory(rng: Random(7));

    expect(store.revealedMask.value, 0, reason: 'Parçalar kapanmalı');
    expect(store.revealedCount, 0);
    expect(store.imageIndex.value, isNot(onceki),
        reason: 'Arka arkaya aynı resim gelmemeli');
  });

  test('Resim havuzdaki bir resmi gösterir', () {
    for (var i = 0; i < puzzleImages.length; i++) {
      store.debugSet(image: i);
      expect(store.image.id, puzzleImages[i].id);
      expect(store.image.label.trim(), isNotEmpty);
    }
  });

  test('Her resmin kimliği ve adı benzersizdir', () {
    final ids = puzzleImages.map((e) => e.id).toSet();
    final labels = puzzleImages.map((e) => e.label).toSet();
    expect(ids.length, puzzleImages.length, reason: 'id çakışması var');
    expect(labels.length, puzzleImages.length, reason: 'ad çakışması var');
  });

  // Bu test kalıcı bir dinleyici bağladığı için dosyanın sonunda durur.
  test('init sonrası kategori değişimi puzzle\'ı kendiliğinden sıfırlar',
      () async {
    await ProgressStore.instance.init();
    await store.init();

    ProgressStore.instance.setCategory(2);
    store.debugSet(image: 0, mask: 0);
    store.revealPiece(rng: Random(1));
    expect(store.revealedCount, 1);

    ProgressStore.instance.setCategory(3);

    expect(store.revealedCount, 0,
        reason: 'Kategori değişince parçalar kapanmalı');
    expect(store.imageIndex.value, isNot(0),
        reason: 'Kategori değişince yeni resim atanmalı');
  });
}
