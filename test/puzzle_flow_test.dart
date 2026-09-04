import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathspin/models/puzzle_image.dart';
import 'package:mathspin/screens/game_screen.dart';
import 'package:mathspin/screens/puzzle_screen.dart';
import 'package:mathspin/services/progress_store.dart';
import 'package:mathspin/services/puzzle_store.dart';
import 'package:mathspin/services/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final puzzle = PuzzleStore.instance;
  final progress = ProgressStore.instance;

  /// Kategoriye atanmış resmin adı (doğru şık).
  String dogruSik() => puzzle.image.label;

  /// Havuzdaki başka bir resmin adı (yanlış şık).
  String yanlisSik() =>
      puzzleImages.firstWhere((e) => e.id != puzzle.image.id).label;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SettingsStore.instance.onboarded = true;
    puzzle.debugSet(image: 0, mask: 0);
    progress.category.value = 4;
  });

  Future<void> acPuzzle(WidgetTester tester,
      {required bool canGuess, int? newPiece}) async {
    await tester.binding.setSurfaceSize(const Size(420, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PuzzleScreen(category: 4, canGuess: canGuess, newPiece: newPiece),
      ),
    );
    await tester.pump();
  }

  testWidgets('Doğru tahmin kategoriyi geçirir', (tester) async {
    puzzle.revealPiece();
    await acPuzzle(tester, canGuess: true, newPiece: 0);

    expect(find.text(dogruSik()), findsOneWidget);

    await tester.tap(find.text(dogruSik()));
    await tester.pump();

    expect(find.text('BİLDİN! 🎉'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));

    expect(progress.category.value, 5, reason: 'Kategori bir artmalı');
    expect(find.text('Mumları üfle! 🎂'), findsOneWidget,
        reason: 'Geçişten sonra pasta kutlaması gelmeli');
  });

  testWidgets('Yanlış tahminde kategori değişmez, parçalar durur',
      (tester) async {
    puzzle.revealPiece();
    puzzle.revealPiece();
    final oncekiMaske = puzzle.revealedMask.value;

    await acPuzzle(tester, canGuess: true, newPiece: null);

    await tester.tap(find.text(yanlisSik()));
    await tester.pump();

    expect(find.text('Bu değil 🙈'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));

    expect(progress.category.value, 4, reason: 'Kategori aynı kalmalı');
    expect(puzzle.revealedMask.value, oncekiMaske,
        reason: 'Açılmış parçalar korunmalı');
    expect(find.byType(GameScreen), findsOneWidget,
        reason: 'Oyun kaldığı kategoriden devam etmeli');
  });

  testWidgets('Tek tahmin hakkı: ilk seçimden sonra şıklar kilitlenir',
      (tester) async {
    puzzle.revealPiece();
    await acPuzzle(tester, canGuess: true, newPiece: null);

    await tester.tap(find.text(yanlisSik()));
    await tester.pump();

    // İkinci bir şıkka basmak durumu değiştirmemeli.
    await tester.tap(find.text(dogruSik()));
    await tester.pump();

    expect(find.text('Bu değil 🙈'), findsOneWidget);
    expect(find.text('BİLDİN! 🎉'), findsNothing);

    // Bekleyen geri dönüş zamanlayıcısını boşalt (test sonunda kalmasın).
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('Baraj geçilmediyse şık yok, parça sayısı görünür',
      (tester) async {
    puzzle.revealPiece();
    puzzle.revealPiece();
    puzzle.revealPiece();

    await acPuzzle(tester, canGuess: false);

    expect(find.text('3 / 10 parça'), findsOneWidget);
    for (final image in puzzleImages) {
      expect(find.text(image.label), findsNothing);
    }
    expect(find.text('TEKRAR DENE'), findsOneWidget);

    await tester.tap(find.text('TEKRAR DENE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(progress.category.value, 4);
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('Tüm parçalar açıkken tahmin sorulmaya devam eder',
      (tester) async {
    puzzle.debugSet(mask: (1 << PuzzleStore.pieceCount) - 1);

    await acPuzzle(tester, canGuess: true);

    expect(find.text('Resmin tamamı açık!'), findsOneWidget);
    expect(find.text('10 / 10 parça'), findsOneWidget);
    expect(find.text(dogruSik()), findsOneWidget);
  });
}
