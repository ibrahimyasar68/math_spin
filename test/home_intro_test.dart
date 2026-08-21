import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathspin/screens/home_screen.dart';
import 'package:mathspin/services/avatar_store.dart';
import 'package:mathspin/widgets/avatar_picker.dart';

void main() {
  setUp(() => AvatarStore.instance.selectedIndex.value = 0);
  tearDown(() => AvatarStore.instance.selectedIndex.value = 0);

  testWidgets(
      'Açılış bitince ayarlar butonu belirir; ayarlardan avatar seçimi store\'a yansır',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // Giriş animasyonu (2 sn) bitene kadar ilerlet.
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump(const Duration(milliseconds: 500));

    // Sağ üstteki ayarlar (dişli) butonu görünür ve tıklanabilir.
    final gear = find.byIcon(Icons.settings_rounded);
    expect(gear, findsOneWidget);
    await tester.tap(gear);
    // Sayfa geçiş animasyonunu ilerlet (StarryBackground sürekli döndüğü için
    // pumpAndSettle yerine sabit süreli pump kullanıyoruz).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Ayarlar ekranında avatar seçici bulunur.
    expect(find.byType(AvatarPicker), findsOneWidget);

    // Seçicideki 3. avatara dokun -> store indeksi 2 olmalı.
    final chips = find.descendant(
      of: find.byType(AvatarPicker),
      matching: find.byType(GestureDetector),
    );
    expect(chips, findsNWidgets(5));
    await tester.tap(chips.at(2));
    await tester.pump();

    expect(AvatarStore.instance.selectedIndex.value, 2);
  });
}
