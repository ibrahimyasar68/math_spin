import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathspin/models/puzzle_image.dart';
import 'package:mathspin/models/question.dart';
import 'package:mathspin/screens/result_screen.dart';
import 'package:mathspin/screens/victory_screen.dart';
import 'package:mathspin/services/progress_store.dart';
import 'package:mathspin/services/puzzle_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const q = Question(
    a: 1, b: 1, op: MathOp.add, result: 2, missing: MissingSlot.result,
  );

  List<QuestionResult> allCorrect(int n) => [
        for (var i = 0; i < n; i++)
          const QuestionResult(question: q, correct: true, givenAnswer: 2),
      ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProgressStore.instance.stars.value = 0;
    PuzzleStore.instance.debugSet(image: 0, mask: 0);
  });

  testWidgets('Son kategoride doğru tahmin final pastası üzerinden zafere '
      'götürür', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(
          category: ProgressStore.maxCategory,
          results: allCorrect(5),
        ),
      ),
    );
    await tester.pump();

    // Son kategoride de oyun ancak resim bilinince biter.
    await tester.tap(find.text(puzzleImages[0].label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Mumları üfle! 🎂'), findsOneWidget);
    expect(find.text('0 / 10'), findsOneWidget,
        reason: 'Final pastasında 10 mum olmalı');
  });

  testWidgets('Her bitiriş bir yıldız kazandırır', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    expect(ProgressStore.instance.stars.value, 0);

    await tester.pumpWidget(const MaterialApp(home: VictoryScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('ŞAMPİYON!'), findsOneWidget);
    expect(ProgressStore.instance.stars.value, 1,
        reason: 'Bitiriş bir yıldız kazandırmalı');
    expect(find.text('1 / 10 yıldız'), findsOneWidget);

    // Yıldız tamamlanmadığı sürece baştan başlanabilir.
    expect(find.text('BAŞTAN BAŞLA'), findsOneWidget);
    expect(find.text('SON KATEGORİYİ OYNA'), findsOneWidget);
  });

  testWidgets('10. yıldızda oyun tamamen biter; baştan başlama sunulmaz',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 9 yıldız kazanılmış; bu bitiriş 10.'yu getirir.
    ProgressStore.instance.stars.value = ProgressStore.maxStars - 1;

    await tester.pumpWidget(const MaterialApp(home: VictoryScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(ProgressStore.instance.stars.value, ProgressStore.maxStars);
    expect(ProgressStore.instance.isFullyComplete, isTrue);
    expect(find.text('OYUN BİTTİ!'), findsOneWidget);
    expect(find.text('ŞAMPİYON!'), findsNothing);
    expect(find.text('BAŞTAN BAŞLA'), findsNothing,
        reason: 'Oyun tamamen bitince baştan başlama sunulmaz');
  });

  test('Yıldız sayısı üst sınırı aşmaz', () {
    ProgressStore.instance.stars.value = ProgressStore.maxStars;
    ProgressStore.instance.awardStar();
    expect(ProgressStore.instance.stars.value, ProgressStore.maxStars);
  });

  test('Baştan başlamak yıldızları geri almaz', () {
    ProgressStore.instance.setCategory(ProgressStore.maxCategory);
    ProgressStore.instance.awardStar();
    ProgressStore.instance.awardStar();

    ProgressStore.instance.restart();

    expect(ProgressStore.instance.category.value, 1,
        reason: 'İlerleme başa dönmeli');
    expect(ProgressStore.instance.stars.value, 2,
        reason: 'Kazanılan yıldızlar korunmalı');
  });
}
