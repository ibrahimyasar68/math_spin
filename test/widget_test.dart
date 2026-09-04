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
    // Sadece bulunulan kategori gösterilir; toplam ("/ 20") yazılmaz.
    expect(find.text('Kategori 1'), findsOneWidget);
    expect(find.textContaining('/ 20'), findsNothing);
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
      10, 10, 10, 10, 10, // sıra 1–5
      9, 8, 7, 6, 5, // sıra 6–10
    ];

    for (var band = 0; band < QuestionGenerator.bandCount; band++) {
      for (var pos = 1; pos <= 10; pos++) {
        final cat = band * 10 + pos;
        final want = expected[pos - 1];
        expect(QuestionGenerator.questionCountFor(cat), want,
            reason: 'kategori $cat (bant ${band + 1}, sıra $pos)');
        expect(QuestionGenerator(category: cat).generateAll().length, want,
            reason: 'kategori $cat üretilen soru adedi');
      }
    }

    // Uç noktalar: çizelgedeki kritik kategoriler.
    expect(QuestionGenerator.questionCountFor(5), 10);
    expect(QuestionGenerator.questionCountFor(10), 5);
    expect(QuestionGenerator.questionCountFor(11), 10);
    expect(QuestionGenerator.questionCountFor(20), 5);
    expect(QuestionGenerator.maxCategory, 20,
        reason: 'İki bantlı planda oyun 20 kategoride biter');
  });

  test('1. bantta (kategori 1–10) sayılar hep tek basamaklıdır', () {
    int digits(int n) => n.toString().length;

    for (final cat in [1, 5, 10]) {
      for (var trial = 0; trial < 20; trial++) {
        final qs = QuestionGenerator(category: cat).generateAll();
        // Çarpan/bölen kasıtlı küçük tutulduğu için toplama/çıkarmaya bakarız.
        for (final q in qs
            .where((q) => q.op == MathOp.add || q.op == MathOp.sub)) {
          expect(digits(q.a), 1, reason: 'kategori $cat: ${q.prompt}');
          expect(digits(q.b), 1, reason: 'kategori $cat: ${q.prompt}');
        }
        // Çarpma/bölmede ilk sayı da banda uymalı.
        for (final q in qs
            .where((q) => q.op == MathOp.mul || q.op == MathOp.div)) {
          expect(digits(q.a), 1, reason: 'kategori $cat ilk sayı: ${q.prompt}');
        }
      }
    }
  });

  test('2. bantta sayılar iki basamağı aşmaz; %5 oranında tek basamaklı gelir',
      () {
    int digits(int n) => n.toString().length;
    const mixRatio = 0.05;

    for (final cat in [11, 16, 20]) {
      var total = 0;
      var smaller = 0;

      for (var trial = 0; trial < 300; trial++) {
        for (final q in QuestionGenerator(category: cat).generateAll()) {
          // İlk sayı hiçbir zaman bandın basamağını aşmamalı.
          expect(digits(q.a), lessThanOrEqualTo(2),
              reason: 'kategori $cat ilk sayı: ${q.prompt}');
          total++;
          if (digits(q.a) < 2) smaller++;
        }
      }

      // Karışım kararı soru başına verildiği için gözlenen oran doğrudan
      // mixRatio'ya oturur (işlem türünden bağımsız).
      final observed = smaller / total;
      expect(observed, greaterThan(0.0),
          reason: 'kategori $cat: tek basamaklı sayı hiç çıkmadı');
      expect(observed, closeTo(mixRatio, 0.02),
          reason: 'kategori $cat: karışım oranı ~$mixRatio olmalı, $observed');
    }
  });

  test('Bölme soruları her bantta tam sayı sonuç verir', () {
    for (final cat in [8, 18, 20]) {
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
    expect(ProgressStore.instance.category.value, 20,
        reason: '20 son kategoridir, aşılamaz');

    ProgressStore.instance.setCategory(0);
    expect(ProgressStore.instance.category.value, 1);
  });
}
