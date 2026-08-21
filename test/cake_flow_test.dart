import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathspin/models/question.dart';
import 'package:mathspin/screens/result_screen.dart';

void main() {
  testWidgets('Kategori geçilince SONRAKİ KATEGORİ yaş pastaya götürür',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const q = Question(
      a: 1, b: 1, op: MathOp.add, result: 2, missing: MissingSlot.result,
    );
    // 8 doğru + 2 yanlış = 80 puan -> barajı geçer.
    final results = <QuestionResult>[
      for (var i = 0; i < 8; i++)
        const QuestionResult(question: q, correct: true, givenAnswer: 2),
      for (var i = 0; i < 2; i++)
        const QuestionResult(question: q, correct: false, givenAnswer: 0),
    ];

    await tester.pumpWidget(
      MaterialApp(home: ResultScreen(category: 3, results: results)),
    );
    await tester.pump();

    expect(find.text('SONRAKİ KATEGORİ'), findsOneWidget);

    await tester.tap(find.text('SONRAKİ KATEGORİ'));
    await tester.pump(); // geçiş animasyonu başlar
    await tester.pump(const Duration(milliseconds: 400)); // tamamlanır

    // Yaş pasta ekranı: geçilen kategori (3) kadar mum, henüz sönmemiş.
    expect(find.text('Mumları üfle! 🎂'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
  });

  testWidgets('Baraj altında TEKRAR DENE doğrudan oyuna götürür (pasta yok)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const q = Question(
      a: 1, b: 1, op: MathOp.add, result: 2, missing: MissingSlot.result,
    );
    // 5 doğru = 50 puan -> geçemez.
    final results = <QuestionResult>[
      for (var i = 0; i < 5; i++)
        const QuestionResult(question: q, correct: true, givenAnswer: 2),
      for (var i = 0; i < 5; i++)
        const QuestionResult(question: q, correct: false, givenAnswer: 0),
    ];

    await tester.pumpWidget(
      MaterialApp(home: ResultScreen(category: 3, results: results)),
    );
    await tester.pump();

    expect(find.text('TEKRAR DENE'), findsOneWidget);
    expect(find.text('SONRAKİ KATEGORİ'), findsNothing);
  });

  testWidgets('Yüzde puanlama: her soru adedinde baraj geçilebilir',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const q = Question(
      a: 1, b: 1, op: MathOp.add, result: 2, missing: MissingSlot.result,
    );

    Future<bool> passes(int total, int correct) async {
      final results = <QuestionResult>[
        for (var i = 0; i < correct; i++)
          const QuestionResult(question: q, correct: true, givenAnswer: 2),
        for (var i = 0; i < total - correct; i++)
          const QuestionResult(question: q, correct: false, givenAnswer: 0),
      ];
      await tester.pumpWidget(
        MaterialApp(home: ResultScreen(category: 3, results: results)),
      );
      await tester.pump();
      return find.text('SONRAKİ KATEGORİ').evaluate().isNotEmpty;
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
