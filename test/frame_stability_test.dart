import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathspin/screens/game_screen.dart';
import 'package:mathspin/widgets/candy_button.dart';
import 'package:mathspin/widgets/slot_reel.dart';

void main() {
  testWidgets('Soru çerçevesi ÇEVİR ve cevap fazlarında aynı yerde durur',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pump();

    // Çerçevenin (slot makinesi) ekrandaki dikdörtgeni.
    Rect frameRect() {
      final reels = find.byType(SlotReel);
      expect(reels, findsNWidgets(3));
      final rects = [
        for (var i = 0; i < 3; i++) tester.getRect(reels.at(i)),
      ];
      return rects.reduce((a, b) => a.expandToInclude(b));
    }

    // 1) ÇEVİR fazı.
    expect(find.text('ÇEVİR'), findsOneWidget);
    final beforeSpin = frameRect();

    // 2) Cevap fazına geç.
    await tester.tap(find.text('ÇEVİR'));
    for (var i = 0; i < 40 && find.text('TAMAM').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('TAMAM'), findsOneWidget);
    final answering = frameRect();

    // 3) Rakam girmek de düzeni oynatmamalı.
    await tester.tap(find.widgetWithText(CandyButton, '7'));
    await tester.pump();
    final afterDigit = frameRect();

    expect(answering, beforeSpin,
        reason: 'ÇEVİR fazı ile cevap fazında çerçeve AYNI olmalı.\n'
            'ÇEVİR: $beforeSpin\ncevap : $answering');
    expect(afterDigit, answering,
        reason: 'Rakam girilince çerçeve oynamamalı');
  });

  testWidgets('ÇEVİR butonu TAMAM ile aynı yerde ve aynı boyutta durur',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pump();

    final spinRect = tester.getRect(find.widgetWithText(CandyButton, 'ÇEVİR'));

    await tester.tap(find.text('ÇEVİR'));
    for (var i = 0; i < 40 && find.text('TAMAM').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final submitRect = tester.getRect(find.widgetWithText(CandyButton, 'TAMAM'));

    expect(spinRect, submitRect,
        reason: 'Çocuk fazlar arasında parmağını taşımamalı.\n'
            'ÇEVİR: $spinRect\nTAMAM: $submitRect');
  });
}
