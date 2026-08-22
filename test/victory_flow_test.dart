import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathspin/models/question.dart';
import 'package:mathspin/screens/result_screen.dart';
import 'package:mathspin/screens/victory_screen.dart';
import 'package:mathspin/services/progress_store.dart';
import 'package:mathspin/widgets/mascot.dart';
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
    ProgressStore.instance.completed.value = false;
  });

  testWidgets('Son kategori geçilince OYUNU BİTİR pasta üzerinden zafere '
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

    // Son kategoride buton "OYUNU BİTİR" olmalı.
    expect(find.text('OYUNU BİTİR'), findsOneWidget);
    expect(find.text('SONRAKİ KATEGORİ'), findsNothing);

    await tester.tap(find.text('OYUNU BİTİR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Önce final pastası gelir.
    expect(find.text('Mumları üfle! 🎂'), findsOneWidget);
    expect(find.text('0 / 10'), findsOneWidget,
        reason: 'Final pastasında 10 mum olmalı');
  });

  testWidgets('Zafer ekranı şampiyonluğu kalıcı kılar ve ödülü açar',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    expect(ProgressStore.instance.completed.value, isFalse);

    await tester.pumpWidget(const MaterialApp(home: VictoryScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('ŞAMPİYON!'), findsOneWidget);
    expect(find.text('BAŞTAN BAŞLA'), findsOneWidget);
    expect(find.text('SON KATEGORİYİ OYNA'), findsOneWidget);

    // Bitirme kalıcı olarak işaretlenir -> ödül avatarının kilidi açılır.
    expect(ProgressStore.instance.completed.value, isTrue);
    expect(find.text('🔓 Yeni avatar açıldı!'), findsOneWidget);
  });

  test('Baştan başlamak şampiyonluğu geri almaz', () {
    ProgressStore.instance.setCategory(ProgressStore.maxCategory);
    ProgressStore.instance.markCompleted();

    ProgressStore.instance.restart();

    expect(ProgressStore.instance.category.value, 1,
        reason: 'İlerleme başa dönmeli');
    expect(ProgressStore.instance.completed.value, isTrue,
        reason: 'Kazanılan şampiyonluk ve ödül avatarı korunmalı');
  });

  test('Ödül avatarı listenin sonundadır', () {
    expect(championSkinIndex, mascotSkins.length - 1);
    expect(mascotSkins[championSkinIndex].name, 'Şampiyon');
  });
}
