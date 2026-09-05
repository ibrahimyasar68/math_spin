import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mathspin/services/settings_store.dart';
import 'package:mathspin/screens/home_screen.dart';
import 'package:mathspin/screens/game_screen.dart';
import 'package:mathspin/widgets/candy_button.dart';

void main() {
  testWidgets('Küçük ekranda klavye ve TAMAM taşmadan sığar', (tester) async {
    // Kısa, gerçekçi bir telefon ekranı (taşma yaşanan senaryo).
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pump();

    await tester.tap(find.text('ÇEVİR'));
    for (var i = 0; i < 40 && find.text('TAMAM').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Taşma istisnası oluşmamalı.
    expect(tester.takeException(), isNull);

    // TAMAM butonu ekran sınırları içinde olmalı (kaydırma gerekmemeli).
    final tamamRect = tester.getRect(find.text('TAMAM'));
    expect(tamamRect.bottom, lessThanOrEqualTo(640),
        reason: 'TAMAM ekranın altına taşmamalı');
    expect(tamamRect.top, greaterThanOrEqualTo(0));

    // Klavye tuşu da görünür olmalı.
    final key5 = tester.getRect(find.widgetWithText(CandyButton, '5'));
    expect(key5.bottom, lessThanOrEqualTo(640));

    // Doğrudan dokunup cevap girilebilmeli (kaydırmadan).
    final key9 = find.widgetWithText(CandyButton, '9');
    await tester.tap(key9);
    await tester.pump();
    expect(find.text('9'), findsWidgets);
  });

  testWidgets('Küçük ekranda ana ekran taşmadan sığar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    SettingsStore.instance.onboarded = true;

    // Taşma olursa pump sırasında hata fırlar; testin geçmesi sığdığını söyler.
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.text('BAŞLA'), findsOneWidget);
    expect(find.text('MathSpin'), findsOneWidget);
  });
}
