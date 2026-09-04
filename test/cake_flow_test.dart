import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathspin/models/puzzle_image.dart';
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

  testWidgets('Barajı geçince puzzle ekranı gelir; doğru tahmin yaş pastaya '
      'götürür', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 8 doğru + 2 yanlış = 80 puan -> barajı geçer.
    await tester.pumpWidget(
      MaterialApp(home: ResultScreen(category: 3, results: score(10, 8))),
    );
    await tester.pump();

    expect(find.text('PARÇAYI GÖR'), findsOneWidget);
    // Baraj artık kategoriyi geçirmiyor, bir parça açıyor.
    expect(PuzzleStore.instance.revealedCount, 1);

    await tester.tap(find.text('PARÇAYI GÖR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Yeni parça açıldı!'), findsOneWidget);
    expect(find.text('1 / 10 parça'), findsOneWidget);

    // Doğru şıkka basınca kategori geçilir ve pasta kutlaması gelir.
    await tester.tap(find.text(puzzleImages[0].label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600)); // geri bildirim
    await tester.pump(const Duration(milliseconds: 400)); // geçiş

    expect(find.text('Mumları üfle! 🎂'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget,
        reason: 'Geçilen kategori (3) kadar mum olmalı');
  });

  testWidgets('Baraj altında parça açılmaz ve tahmin hakkı verilmez',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 5 doğru = 50 puan -> geçemez.
    await tester.pumpWidget(
      MaterialApp(home: ResultScreen(category: 3, results: score(10, 5))),
    );
    await tester.pump();

    expect(find.text('BULMACAYA GEÇ'), findsOneWidget);
    expect(find.text('PARÇAYI GÖR'), findsNothing);
    expect(PuzzleStore.instance.revealedCount, 0);

    await tester.tap(find.text('BULMACAYA GEÇ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Parça kazanamadın'), findsOneWidget);
    expect(find.text('0 / 10 parça'), findsOneWidget);
    // Şık yok; yalnızca oyuna dönüş butonu var.
    for (final image in puzzleImages) {
      expect(find.text(image.label), findsNothing,
          reason: 'Baraj geçilmeden tahmin şıkkı gösterilmemeli');
    }
    expect(find.text('TEKRAR DENE'), findsOneWidget);
  });

  testWidgets('Yüzde puanlama: her soru adedinde baraj geçilebilir',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<bool> passes(int total, int correct) async {
      PuzzleStore.instance.debugSet(mask: 0);
      await tester.pumpWidget(
        MaterialApp(home: ResultScreen(category: 3, results: score(total, correct))),
      );
      await tester.pump();
      return find.text('PARÇAYI GÖR').evaluate().isNotEmpty;
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
