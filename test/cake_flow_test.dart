import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathspin/models/question.dart';
import 'package:mathspin/screens/result_screen.dart';
import 'package:mathspin/services/puzzle_store.dart';

void main() {
  const q = Question(
    a: 1, b: 1, op: MathOp.add, result: 2, missing: MissingSlot.result,
  );

  List<QuestionResult> score(int total, int correct) => [
        for (var i = 0; i < correct; i++)
          const QuestionResult(question: q, correct: true, givenAnswer: 2),
        for (var i = 0; i < total - correct; i++)
          const QuestionResult(question: q, correct: false, givenAnswer: 0),
      ];

  setUp(() {
    // Puzzle tekil örneği testler arasında taşınmasın.
    PuzzleStore.instance.debugSet(image: 0, mask: 0);
  });

  testWidgets('Doğru tahminden sonra geçilen kategori kadar mum yanar',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 8 doğru + 2 yanlış = 80 puan -> barajı geçer, bir parça açılır.
    await tester.pumpWidget(
      MaterialApp(home: ResultScreen(category: 3, results: score(10, 8))),
    );
    await tester.pump();

    await tester.tap(find.text(PuzzleStore.instance.image.label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Mumları üfle! 🎂'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget,
        reason: 'Geçilen kategori (3) kadar mum olmalı');
  });

  testWidgets('Yüzde puanlama: her soru adedinde baraj geçilebilir',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    /// Baraj geçildiyse bir parça açılır; ölçüt bu.
    ///
    /// Her çağrıda farklı bir anahtar veriyoruz: aynı türden bir widget aynı
    /// anahtarla yeniden pump edilirse Flutter var olan State'i yeniden kullanır
    /// ve `initState` (dolayısıyla parça açma) bir daha çalışmaz.
    Future<bool> passes(int total, int correct) async {
      PuzzleStore.instance.debugSet(mask: 0);
      await tester.pumpWidget(
        MaterialApp(
          home: ResultScreen(
            key: ValueKey('$total-$correct'),
            category: 3,
            results: score(total, correct),
          ),
        ),
      );
      await tester.pump();
      return PuzzleStore.instance.revealedCount == 1;
    }

    // soru adedi -> geçmek için gereken en az doğru (%80 baraj).
    const needed = {10: 8, 9: 8, 8: 7, 7: 6, 6: 5, 5: 4};

    for (final entry in needed.entries) {
      final total = entry.key;
      final need = entry.value;

      expect(await passes(total, need), isTrue,
          reason: '$total soruda $need doğru barajı geçmeli');
      expect(await passes(total, need - 1), isFalse,
          reason: '$total soruda ${need - 1} doğru barajı geçmemeli');
    }
  });
}
