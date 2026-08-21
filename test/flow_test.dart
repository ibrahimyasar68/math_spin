import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathspin/screens/game_screen.dart';
import 'package:mathspin/widgets/candy_button.dart';

void main() {
  testWidgets('Yanlış cevap da sonraki soruya geçirir', (tester) async {
    // Telefon boyutu: klavye ve butonlar ekran içinde kalsın.
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pump();

    // ÇEVİR (benzersiz metin).
    await tester.tap(find.text('ÇEVİR'));

    // Dönüş bitip cevap aşaması gelene kadar adım adım pump et (starfield
    // animasyonu repeat olduğu için pumpAndSettle kullanılamaz).
    for (var i = 0; i < 40 && find.text('TAMAM').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('TAMAM'), findsOneWidget);

    // Kasıtlı çok büyük (yanlış) cevap gir: '9' rakamı çarkta da olabileceği için
    // yalnızca klavyedeki CandyButton içindeki '9'u hedefle.
    final key9 = find.widgetWithText(CandyButton, '9');
    await tester.tap(key9);
    await tester.tap(key9);
    await tester.tap(key9);
    await tester.pump();
    await tester.tap(find.text('TAMAM'));
    await tester.pump();

    // Reveal + bekleme sonrası 2. soruya geçmeli.
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();

    expect(find.text('Soru 2 / 10'), findsOneWidget,
        reason: 'Yanlış cevaptan sonra sonraki soruya geçmeli');
    expect(find.text('ÇEVİR'), findsOneWidget,
        reason: 'Yeni soru ÇEVİR ile başlamalı');
    expect(find.text('Kategori 1'), findsOneWidget,
        reason: 'Oyun ekranının üstünde kategori görünmeli');
  });
}
