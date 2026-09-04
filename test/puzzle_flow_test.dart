import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathspin/models/puzzle_image.dart';
import 'package:mathspin/models/question.dart';
import 'package:mathspin/screens/game_screen.dart';
import 'package:mathspin/screens/result_screen.dart';
import 'package:mathspin/services/progress_store.dart';
import 'package:mathspin/services/puzzle_store.dart';
import 'package:mathspin/services/settings_store.dart';
import 'package:mathspin/widgets/puzzle_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final puzzle = PuzzleStore.instance;
  final progress = ProgressStore.instance;

  const q = Question(
    a: 1, b: 1, op: MathOp.add, result: 2, missing: MissingSlot.result,
  );

  List<QuestionResult> score(int total, int correct) => [
        for (var i = 0; i < correct; i++)
          const QuestionResult(question: q, correct: true, givenAnswer: 2),
        for (var i = 0; i < total - correct; i++)
          const QuestionResult(question: q, correct: false, givenAnswer: 0),
      ];

  /// Kategoriye atanmış resmin adı (doğru şık).
  String dogruSik() => puzzle.image.label;

  /// Ekranda görünen şıklardan doğru olmayan biri.
  ///
  /// Şıklar rastgele çekildiği için hangi yanlışların geldiği önceden belli
  /// değil; ekrandan okuyoruz.
  String yanlisSik() {
    for (final image in puzzleImages) {
      if (image.id == puzzle.image.id) continue;
      if (find.text(image.label).evaluate().isNotEmpty) return image.label;
    }
    fail('Ekranda yanlış şık bulunamadı');
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SettingsStore.instance.onboarded = true;
    puzzle.debugSet(image: 0, mask: 0);
    progress.category.value = 4;
  });

  /// Oyundaki gerçek uzunlukla aynı: her kategori 5 soru.
  Future<void> sonucEkrani(WidgetTester tester, {required int dogru}) async {
    await tester.binding.setSurfaceSize(const Size(420, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: ResultScreen(category: 4, results: score(5, dogru))),
    );
    await tester.pump();
  }

  testWidgets('Yapboz sonuç ekranının içinde: ayrı ekran açılmaz',
      (tester) async {
    await sonucEkrani(tester, dogru: 4);

    // Puan şeridi ve yapboz aynı ekranda.
    expect(find.text('Kategori 4'), findsOneWidget);
    expect(find.text('1 / 10 parça'), findsOneWidget);
    expect(find.text(dogruSik()), findsOneWidget);
  });

  testWidgets('Barajı geçmek bir parça açar', (tester) async {
    await sonucEkrani(tester, dogru: 4);

    expect(puzzle.revealedCount, 1);
    expect(find.text('Yeni parça açıldı!'), findsOneWidget);
  });

  testWidgets('Baraj altında yapboz hiç gösterilmez, kategori başarısız olur',
      (tester) async {
    await sonucEkrani(tester, dogru: 2);

    expect(puzzle.revealedCount, 0, reason: 'Parça yalnızca barajla gelir');
    expect(find.text('BAŞARISIZ'), findsOneWidget);
    expect(find.textContaining('Kategori 4 baştan'), findsOneWidget);

    // Ne tahta ne sayaç ne şık: yapbozun hiçbir parçası görünmemeli.
    expect(find.byType(PuzzlePanel), findsNothing);
    expect(find.textContaining('/ 10 parça'), findsNothing,
        reason: 'Parça sayacı görünmemeli');
    for (final image in puzzleImages) {
      expect(find.text(image.label), findsNothing);
    }
  });

  testWidgets('Başarısız kategoride TEKRAR DENE aynı kategoriye döndürür',
      (tester) async {
    await sonucEkrani(tester, dogru: 2);

    await tester.tap(find.text('TEKRAR DENE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(progress.category.value, 4, reason: 'Kategori değişmemeli');
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('Dört şık gelir ve doğru cevap her zaman içindedir',
      (tester) async {
    await sonucEkrani(tester, dogru: 4);

    final gorunen = [
      for (final image in puzzleImages)
        if (find.text(image.label).evaluate().isNotEmpty) image.label,
    ];
    expect(gorunen.length, 4, reason: 'Şık sayısı dört olmalı');
    expect(gorunen, contains(dogruSik()));
  });

  testWidgets('Doğru tahmin kategoriyi geçirir ve pastaya götürür',
      (tester) async {
    await sonucEkrani(tester, dogru: 4);

    await tester.tap(find.text(dogruSik()));
    await tester.pump();
    expect(find.text('BİLDİN! 🎉'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));

    expect(progress.category.value, 5, reason: 'Kategori bir artmalı');
    expect(find.text('Mumları üfle! 🎂'), findsOneWidget);
  });

  testWidgets('Yanlış tahminde kategori değişmez, parçalar durur',
      (tester) async {
    await sonucEkrani(tester, dogru: 4);
    final oncekiMaske = puzzle.revealedMask.value;

    await tester.tap(find.text(yanlisSik()));
    await tester.pump();
    expect(find.text('Bu değil 🙈'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));

    expect(progress.category.value, 4, reason: 'Kategori aynı kalmalı');
    expect(puzzle.revealedMask.value, oncekiMaske,
        reason: 'Açılmış parçalar korunmalı');
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('Tek tahmin hakkı: ilk seçimden sonra şıklar kilitlenir',
      (tester) async {
    await sonucEkrani(tester, dogru: 4);

    await tester.tap(find.text(yanlisSik()));
    await tester.pump();
    await tester.tap(find.text(dogruSik()));
    await tester.pump();

    expect(find.text('Bu değil 🙈'), findsOneWidget);
    expect(find.text('BİLDİN! 🎉'), findsNothing);

    // Bekleyen geri dönüş zamanlayıcısını boşalt.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('Tüm parçalar açıkken tahmin sorulmaya devam eder',
      (tester) async {
    puzzle.debugSet(mask: (1 << PuzzleStore.pieceCount) - 1);
    // Tüm parçalar zaten açık: barajı geçse de yeni parça gelmez.
    await sonucEkrani(tester, dogru: 4);

    expect(find.text('Resmin tamamı açık!'), findsOneWidget);
    expect(find.text('10 / 10 parça'), findsOneWidget);
    expect(find.text(dogruSik()), findsOneWidget);
  });
}
