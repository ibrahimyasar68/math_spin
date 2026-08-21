import 'dart:math';

import '../models/question.dart';

/// Seçilen kategoriye göre 10 soruluk bir set üretir.
///
/// İşlemlerdeki sayıların basamak adedi kategori bandına bağlıdır. Sonucun
/// basamak adedi ayrıca kısıtlanmaz, işlemin doğal çıktısıdır.
///
///   - Kategori 1–15 : tek basamaklı sayılar   (1–9)
///   - Kategori 16–30: iki basamaklı sayılar    (10–99)
///   - Kategori 31–45: üç basamaklı sayılar     (100–999)  — %10 oranında
///                     bazı sayılar 1–2 basamaklı da olabilir
///   - Kategori 46–60: dört basamaklı sayılar   (1000–9999) — %15 oranında
///                     bazı sayılar 1–3 basamaklı da olabilir
///
/// Bant içi çeşitlilik: bandın başında yalnız toplama/çıkarma, ortasında
/// çarpma, sonunda bölme de eklenir.
///
/// Çarpma ve bölmede yalnız ilk sayı banda göre büyür; çarpan/bölen çocuk
/// dostu ve sonuç girilebilir kalması için 2–9 aralığında tutulur.
class QuestionGenerator {
  static const int totalQuestions = 10;
  static const int maxCategory = 60;

  final int category;
  final Random _rng;

  QuestionGenerator({this.category = 1, Random? rng})
      : assert(category >= 1 && category <= maxCategory),
        _rng = rng ?? Random();

  // ---- Kategori -> zorluk parametreleri -----------------------------------

  /// Kategorinin basamak bandı: basamak adedi, sayı aralığı [lo, hi], bandın
  /// kapsadığı ilk/son kategori ve daha küçük basamaklı sayı çıkma olasılığı
  /// ([mixRatio]; 0 = yalnız bandın kendi basamağı).
  ({int digits, int lo, int hi, int first, int last, double mixRatio})
      get _band {
    if (category <= 15) {
      return (digits: 1, lo: 1, hi: 9, first: 1, last: 15, mixRatio: 0.0);
    }
    if (category <= 30) {
      return (digits: 2, lo: 10, hi: 99, first: 16, last: 30, mixRatio: 0.0);
    }
    if (category <= 45) {
      // %10 oranında 1–2 basamaklı sayılar da karışır.
      return (digits: 3, lo: 100, hi: 999, first: 31, last: 45, mixRatio: 0.10);
    }
    // 46–60 (60 son kategori): %15 oranında 1–3 basamaklı sayılar da karışır.
    return (
      digits: 4,
      lo: 1000,
      hi: 9999,
      first: 46,
      last: 60,
      mixRatio: 0.15
    );
  }

  /// Banttan bir işlem sayısı üretir.
  ///
  /// [mixRatio] olasılıkla daha küçük basamaklı (1..digits-1 arası rastgele
  /// seçilen bir basamak adedinde) bir sayı döner; böylece üst bantlarda
  /// arada kolay sayılar da görünür.
  /// Bir sorunun sayılarının çekileceği aralık: [mixRatio] olasılıkla daha
  /// küçük basamaklı bir aralık, aksi hâlde bandın kendi aralığı.
  ({int lo, int hi}) _operandRange() {
    final b = _band;
    if (b.mixRatio > 0 && b.digits > 1 && _rng.nextDouble() < b.mixRatio) {
      final digits = _between(1, b.digits - 1);
      return (
        lo: digits == 1 ? 1 : _pow10(digits - 1),
        hi: _pow10(digits) - 1,
      );
    }
    return (lo: b.lo, hi: b.hi);
  }

  int _pow10(int e) {
    var v = 1;
    for (var i = 0; i < e; i++) {
      v *= 10;
    }
    return v;
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
    // Karışım kararı soru başına bir kez verilir: "kolay" soruda sorunun tüm
    // sayıları küçük basamaklıdır. Sayı başına karar verilseydi çıkarmadaki
    // a >= b takası küçük sayıyı ikinci sıraya iter ve gözlenen oran
    // [mixRatio]'nun altına düşerdi.
    final range = _operandRange();
    switch (op) {
      case MathOp.add:
        return _buildAddition(range);
      case MathOp.sub:
        return _buildSubtraction(range);
      case MathOp.mul:
        return _buildMultiplication(range);
      case MathOp.div:
        return _buildDivision(range);
    }
  }

  /// [min]..[max] aralığında rastgele tam sayı (her ikisi dahil).
  int _between(int min, int max) => min + _rng.nextInt(max - min + 1);

  MissingSlot _randomMissing() =>
      _rng.nextBool() ? MissingSlot.result : MissingSlot.operandB;

  Question _buildAddition(({int lo, int hi}) range) {
    final a = _between(range.lo, range.hi);
    final bb = _between(range.lo, range.hi);
    return Question(
      a: a,
      b: bb,
      op: MathOp.add,
      result: a + bb,
      missing: _randomMissing(),
    );
  }

  Question _buildSubtraction(({int lo, int hi}) range) {
    // Sonucun negatif olmaması için a >= b garanti edilir.
    var a = _between(range.lo, range.hi);
    var b = _between(range.lo, range.hi);
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

  Question _buildMultiplication(({int lo, int hi}) range) {
    final band = _band;
    // İlk sayı banda göre büyür; çarpan tek basamaklı bantta banttan,
    // büyük bantlarda 2–9 arasından gelir (sonuç makul/girilebilir kalsın).
    final a = _between(range.lo, range.hi);
    final b = band.digits == 1 ? _between(1, 9) : _between(2, 9);
    return Question(
      a: a,
      b: b,
      op: MathOp.mul,
      result: a * b,
      missing: _randomMissing(),
    );
  }

  Question _buildDivision(({int lo, int hi}) range) {
    // Bölünen (a) banda uyar ve tam bölünür: bölen ile bölümü seçip a'yı
    // türetiriz. Geçerli aralık bulunana kadar birkaç kez dener.
    for (var attempt = 0; attempt < 24; attempt++) {
      final divisor = _between(2, 9);
      final maxQuotient = range.hi ~/ divisor;
      final minQuotient = max(2, (range.lo + divisor - 1) ~/ divisor);
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
    return _buildMultiplication(range);
  }
}
