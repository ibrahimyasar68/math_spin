import 'dart:math';

import '../models/question.dart';

/// Seçilen kategoriye göre 10 soruluk bir set üretir.
///
/// İşlemlerdeki sayıların basamak adedi kategori onluğuna bağlıdır; her 10
/// kategoride bir artar. Sonucun basamak adedi ayrıca kısıtlanmaz, işlemin
/// doğal çıktısıdır ("sonuç işleme bağlı").
///
///   - Kategori 1–9  : tek basamaklı sayılar   (1–9)
///   - Kategori 10–19: iki basamaklı sayılar    (10–99)
///   - Kategori 20–29: üç basamaklı sayılar     (100–999)
///   - Kategori 30–39: dört basamaklı sayılar   (1000–9999)
///   - Kategori 40–50: beş basamaklı sayılar    (10000–99999)
///
/// Bant içi çeşitlilik: onluğun başında yalnız toplama/çıkarma, ortasında
/// çarpma, sonunda bölme de eklenir (basamak adedi değişmez).
///
/// Çarpma ve bölmede yalnız ilk sayı banda göre büyür; çarpan/bölen çocuk
/// dostu ve sonuç girilebilir kalması için 2–9 aralığında tutulur (ör. beş
/// basamaklı sayıyı tek basamaklı ile çarpma).
class QuestionGenerator {
  static const int totalQuestions = 10;
  static const int maxCategory = 50;

  final int category;
  final Random _rng;

  QuestionGenerator({this.category = 1, Random? rng})
      : assert(category >= 1 && category <= maxCategory),
        _rng = rng ?? Random();

  // ---- Kategori -> zorluk parametreleri -----------------------------------

  /// Kategorinin basamak bandı: basamak adedi, sayı aralığı [lo, hi] ve
  /// bandın kapsadığı ilk/son kategori.
  ({int digits, int lo, int hi, int first, int last}) get _band {
    if (category <= 9) return (digits: 1, lo: 1, hi: 9, first: 1, last: 9);
    if (category <= 19) {
      return (digits: 2, lo: 10, hi: 99, first: 10, last: 19);
    }
    if (category <= 29) {
      return (digits: 3, lo: 100, hi: 999, first: 20, last: 29);
    }
    if (category <= 39) {
      return (digits: 4, lo: 1000, hi: 9999, first: 30, last: 39);
    }
    // 40–50 (50 son kategori)
    return (digits: 5, lo: 10000, hi: 99999, first: 40, last: 50);
  }

  /// Bandın içindeki ilerleme: 0.0 = bandın ilk kategorisi, 1.0 = sonuncusu.
  double get _progress {
    final b = _band;
    if (b.last == b.first) return 1;
    return (category - b.first) / (b.last - b.first);
  }

  /// Bu kategoride sorulabilecek işlemler (onluk içinde kademeli genişler).
  List<MathOp> get _opPool {
    final p = _progress;
    if (p < 0.25) return const [MathOp.add, MathOp.sub];
    if (p < 0.55) return const [MathOp.add, MathOp.sub, MathOp.mul];
    return MathOp.values;
  }

  // ---- Üretim --------------------------------------------------------------

  /// Bu kategori için 10 soruluk listeyi üretir.
  List<Question> generateAll() {
    return List<Question>.generate(totalQuestions, (_) => _generate());
  }

  Question _generate() {
    final pool = _opPool;
    final op = pool[_rng.nextInt(pool.length)];
    switch (op) {
      case MathOp.add:
        return _buildAddition();
      case MathOp.sub:
        return _buildSubtraction();
      case MathOp.mul:
        return _buildMultiplication();
      case MathOp.div:
        return _buildDivision();
    }
  }

  /// [min]..[max] aralığında rastgele tam sayı (her ikisi dahil).
  int _between(int min, int max) => min + _rng.nextInt(max - min + 1);

  MissingSlot _randomMissing() =>
      _rng.nextBool() ? MissingSlot.result : MissingSlot.operandB;

  Question _buildAddition() {
    final b = _band;
    final a = _between(b.lo, b.hi);
    final bb = _between(b.lo, b.hi);
    return Question(
      a: a,
      b: bb,
      op: MathOp.add,
      result: a + bb,
      missing: _randomMissing(),
    );
  }

  Question _buildSubtraction() {
    final band = _band;
    // Sonucun negatif olmaması için a >= b garanti edilir.
    var a = _between(band.lo, band.hi);
    var b = _between(band.lo, band.hi);
    if (b > a) {
      final tmp = a;
      a = b;
      b = tmp;
    }
    return Question(
      a: a,
      b: b,
      op: MathOp.sub,
      result: a - b,
      missing: _randomMissing(),
    );
  }

  Question _buildMultiplication() {
    final band = _band;
    // İlk sayı banda göre büyür; çarpan tek basamaklı bantta banttan,
    // büyük bantlarda 2–9 arasından gelir (sonuç makul/girilebilir kalsın).
    final a = _between(band.lo, band.hi);
    final b = band.digits == 1 ? _between(1, 9) : _between(2, 9);
    return Question(
      a: a,
      b: b,
      op: MathOp.mul,
      result: a * b,
      missing: _randomMissing(),
    );
  }

  Question _buildDivision() {
    final band = _band;
    // Bölünen (a) banda uyar ve tam bölünür: bölen ile bölümü seçip a'yı
    // türetiriz. Geçerli aralık bulunana kadar birkaç kez dener.
    for (var attempt = 0; attempt < 24; attempt++) {
      final divisor = _between(2, 9);
      final maxQuotient = band.hi ~/ divisor;
      final minQuotient = max(2, (band.lo + divisor - 1) ~/ divisor);
      if (minQuotient > maxQuotient) continue; // bu bölenle band'a sığmıyor
      final quotient = _between(minQuotient, maxQuotient);
      final a = divisor * quotient;
      return Question(
        a: a,
        b: divisor,
        op: MathOp.div,
        result: quotient,
        missing: _randomMissing(),
      );
    }
    // Nadir geri dönüş (ör. çok dar band): çarpmaya düş.
    return _buildMultiplication();
  }
}
