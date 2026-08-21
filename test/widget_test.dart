import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathspin/main.dart';
import 'package:mathspin/models/question.dart';
import 'package:mathspin/services/avatar_store.dart';
import 'package:mathspin/services/progress_store.dart';
import 'package:mathspin/services/question_generator.dart';
import 'package:mathspin/services/settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Açılış ekranı yüklenir; BAŞLA ve kategori rozeti görünür',
      (WidgetTester tester) async {
    // İlk açılış onboarding'i tamamlanmış say -> doğrudan ana ekran gelir.
    SettingsStore.instance.onboarded = true;
    await tester.pumpWidget(const MathSpinApp());
    await tester.pump();

    expect(find.text('MathSpin'), findsOneWidget);
    expect(find.text('BAŞLA'), findsOneWidget);
    // Sadece bulunulan kategori gösterilir; toplam ("/ 60") yazılmaz.
    expect(find.text('Kategori 1'), findsOneWidget);
    expect(find.textContaining('/ 60'), findsNothing);
  });

  test('Bant başı kategoride 10 soru; yalnız toplama/çıkarma', () {
    final qs = QuestionGenerator(category: 1).generateAll();
    expect(qs.length, 10);

    for (final q in qs) {
      expect(q.op == MathOp.add || q.op == MathOp.sub, isTrue,
          reason: 'Kategori 1\'de çarpma/bölme olmamalı: ${q.prompt}');
      expect(q.a, inInclusiveRange(1, 9));
      expect(q.b, inInclusiveRange(1, 9));
      if (q.op == MathOp.sub) {
        expect(q.result >= 0, isTrue);
      }
    }
  });

  test('Soru adedi bant içindeki sıraya göre azalır (10..10,9,8,7,6,5)', () {
    // Banttaki sıra -> beklenen soru adedi.
    const expected = [
      10, 10, 10, 10, 10, 10, 10, 10, 10, 10, // sıra 1–10
      9, 8, 7, 6, 5, // sıra 11–15
    ];

    for (var band = 0; band < 4; band++) {
      for (var pos = 1; pos <= 15; pos++) {
        final cat = band * 15 + pos;
        final want = expected[pos - 1];
        expect(QuestionGenerator.questionCountFor(cat), want,
            reason: 'kategori $cat (bant ${band + 1}, sıra $pos)');
        expect(QuestionGenerator(category: cat).generateAll().length, want,
            reason: 'kategori $cat üretilen soru adedi');
      }
    }

    // Uç noktalar: çizelgedeki kritik kategoriler.
    expect(QuestionGenerator.questionCountFor(10), 10);
    expect(QuestionGenerator.questionCountFor(15), 5);
    expect(QuestionGenerator.questionCountFor(16), 10);
    expect(QuestionGenerator.questionCountFor(45), 5);
    expect(QuestionGenerator.questionCountFor(46), 10);
    expect(QuestionGenerator.questionCountFor(60), 5);
  });

  test('Alt bantlarda (1–30) sayılar tam olarak bandın basamağındadır', () {
    int digits(int n) => n.toString().length;
    // kategori -> beklenen basamak sayısı (karışım yok: mixRatio = 0)
    const bands = {
      1: 1, 8: 1, 15: 1, // tek basamaklı
      16: 2, 23: 2, 30: 2, // iki basamaklı
    };

    bands.forEach((cat, d) {
      for (var trial = 0; trial < 20; trial++) {
        final qs = QuestionGenerator(category: cat).generateAll();
        // Çarpan/bölen kasıtlı küçük tutulduğu için toplama/çıkarmaya bakarız.
        for (final q in qs
            .where((q) => q.op == MathOp.add || q.op == MathOp.sub)) {
          expect(digits(q.a), d, reason: 'kategori $cat: ${q.prompt}');
          expect(digits(q.b), d, reason: 'kategori $cat: ${q.prompt}');
        }
        // Çarpma/bölmede ilk sayı da banda uymalı.
        for (final q in qs
            .where((q) => q.op == MathOp.mul || q.op == MathOp.div)) {
          expect(digits(q.a), d, reason: 'kategori $cat ilk sayı: ${q.prompt}');
        }
      }
    });
  });

  test('Üst bantlarda sayılar bandın basamağını aşmaz; karışım oranı makuldür',
      () {
    int digits(int n) => n.toString().length;
    // kategori -> (bandın basamağı, beklenen karışım oranı)
    const bands = {
      31: (3, 0.10), 38: (3, 0.10), 45: (3, 0.10),
      46: (4, 0.15), 53: (4, 0.15), 60: (4, 0.15),
    };

    bands.forEach((cat, spec) {
      final d = spec.$1;
      final ratio = spec.$2;
      var total = 0;
      var smaller = 0;

      for (var trial = 0; trial < 300; trial++) {
        for (final q in QuestionGenerator(category: cat).generateAll()) {
          // İlk sayı hiçbir zaman bandın basamağını aşmamalı.
          expect(digits(q.a), lessThanOrEqualTo(d),
              reason: 'kategori $cat ilk sayı: ${q.prompt}');
          total++;
          if (digits(q.a) < d) smaller++;
        }
      }

      // Karışım kararı soru başına verildiği için gözlenen oran doğrudan
      // mixRatio'ya oturur (işlem türünden bağımsız).
      final observed = smaller / total;
      expect(observed, greaterThan(0.0),
          reason: 'kategori $cat: küçük basamaklı sayı hiç çıkmadı');
      expect(observed, closeTo(ratio, 0.03),
          reason: 'kategori $cat: karışım oranı ~$ratio olmalı, $observed');
    });
  });

  test('Bölme soruları her bantta tam sayı sonuç verir', () {
    for (final cat in [12, 28, 40, 60]) {
      final gen = QuestionGenerator(category: cat);
      for (var trial = 0; trial < 100; trial++) {
        for (final q in gen.generateAll().where((q) => q.op == MathOp.div)) {
          expect(q.a % q.b, 0,
              reason: 'kategori $cat: ${q.a} ÷ ${q.b} tam bölünmeli');
          expect(q.a ~/ q.b, q.result);
        }
      }
    }
  });

  test('ProgressStore kayıtlı ilerlemeden devam eder ve sınırları uygular',
      () async {
    SharedPreferences.setMockInitialValues({
      'player.category': 12,
      'player.avatarIndex': 2,
    });

    await ProgressStore.instance.init();
    expect(ProgressStore.instance.category.value, 12,
        reason: 'Kayıtlı kategoriden devam etmeli');
    expect(AvatarStore.instance.selectedIndex.value, 2,
        reason: 'Kayıtlı avatar geri yüklenmeli');

    ProgressStore.instance.setCategory(99);
    expect(ProgressStore.instance.category.value, 60,
        reason: '60 son kategoridir, aşılamaz');

    ProgressStore.instance.setCategory(0);
    expect(ProgressStore.instance.category.value, 1);
  });
}
