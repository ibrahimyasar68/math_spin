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
    // Sadece bulunulan kategori gösterilir; toplam ("/ 50") yazılmaz.
    expect(find.text('Kategori 1'), findsOneWidget);
    expect(find.textContaining('/ 50'), findsNothing);
  });

  test('Her kategori 10 soru üretir; bant başında yalnız toplama/çıkarma', () {
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

  test('İşlemlerdeki sayıların basamağı her 10 kategoride bir artar', () {
    int digits(int n) => n.toString().length;
    // kategori -> beklenen basamak sayısı (onluk bantlar)
    const bands = {
      1: 1, 9: 1, // tek basamaklı
      10: 2, 19: 2, // iki basamaklı
      20: 3, 29: 3, // üç basamaklı
      30: 4, 39: 4, // dört basamaklı
      40: 5, 49: 5, 50: 5, // beş basamaklı
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

  test('Bölme soruları her bantta tam sayı sonuç verir', () {
    for (final cat in [7, 19, 35, 50]) {
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
    expect(ProgressStore.instance.category.value, 50,
        reason: '50 son kategoridir, aşılamaz');

    ProgressStore.instance.setCategory(0);
    expect(ProgressStore.instance.category.value, 1);
  });
}
