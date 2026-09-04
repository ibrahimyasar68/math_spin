import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathspin/models/puzzle_image.dart';
import 'package:mathspin/services/progress_store.dart';
import 'package:mathspin/services/puzzle_store.dart';
import 'package:mathspin/widgets/puzzle_board.dart';
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

  group('Tahmin şıkları', () {
    test('Dört şık gelir, doğru cevap içinde ve tekrar yok', () {
      for (final correct in puzzleImages) {
        final secenekler = buildChoices(correct, rng: Random(correct.id.length));
        expect(secenekler.length, 4);
        expect(secenekler.map((e) => e.id), contains(correct.id));
        expect(secenekler.map((e) => e.id).toSet().length, 4,
            reason: 'Aynı şık iki kez gelmemeli');
      }
    });

    test('Şıklar her çağrıda yeniden karılır', () {
      final a = buildChoices(puzzleImages[0], rng: Random(1));
      final b = buildChoices(puzzleImages[0], rng: Random(2));
      expect(a.map((e) => e.id).toList(), isNot(b.map((e) => e.id).toList()),
          reason: 'Aynı yanlışlar hep aynı sırayla gelirse eleme kolaylaşır');
    });

    test('Havuz şık sayısını karşılayacak kadar büyük', () {
      expect(puzzleImages.length, greaterThanOrEqualTo(4));
    });
  });

  group('Yapboz geometrisi', () {
    const size = Size(300, 300);

    test('Parçalar tahtanın tamamını boşluksuz kaplar', () {
      for (final image in puzzleImages.take(3)) {
        var birlesim = puzzlePiecePath(image.id, 0, size);
        for (var i = 1; i < PuzzleStore.pieceCount; i++) {
          birlesim = Path.combine(
            PathOperation.union,
            birlesim,
            puzzlePiecePath(image.id, i, size),
          );
        }
        final tahta = Path()..addRect(Offset.zero & size);
        final eksik = Path.combine(PathOperation.difference, tahta, birlesim);
        final fazla = Path.combine(PathOperation.difference, birlesim, tahta);

        expect(_alan(eksik), lessThan(2.0),
            reason: '${image.id}: parçalar arasında boşluk kalmamalı');
        expect(_alan(fazla), lessThan(2.0),
            reason: '${image.id}: parçalar tahtanın dışına taşmamalı');
      }
    });

    test('Komşu parçalar üst üste binmez', () {
      // Yan yana (0-1) ve alt alta (0-2) iki komşu.
      for (final ikili in [[0, 1], [0, 2]]) {
        final kesisim = Path.combine(
          PathOperation.intersect,
          puzzlePiecePath('at', ikili[0], size),
          puzzlePiecePath('at', ikili[1], size),
        );
        expect(_alan(kesisim), lessThan(2.0),
            reason: 'Parça ${ikili[0]} ile ${ikili[1]} çakışıyor');
      }
    });
  });
}

/// Bir yolun kapladığı yaklaşık alan (piksel kare).
///
/// Tam alan hesabı yerine ızgara taraması: yalnızca "neredeyse boş mu" sorusunu
/// yanıtlamak için yeterli ve kütüphaneden bağımsız.
double _alan(Path path) {
  final b = path.getBounds();
  if (b.isEmpty) return 0;
  const adim = 0.5;
  var sayac = 0;
  for (var x = b.left; x <= b.right; x += adim) {
    for (var y = b.top; y <= b.bottom; y += adim) {
      if (path.contains(Offset(x, y))) sayac++;
    }
  }
  return sayac * adim * adim;
}
