import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathspin/screens/game_screen.dart';
import 'package:mathspin/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProgressStore.instance.setCategory(1);
  });

  tearDown(() => ProgressStore.instance.stars.value = 0);

  /// Oyun ekranındaki yıldız simgelerinin ekrandaki konumları.
  Future<List<Offset>> starCenters(WidgetTester tester, int stars) async {
    ProgressStore.instance.stars.value = stars;
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pump();

    final icons = find.byIcon(Icons.star_rounded);
    return [
      for (var i = 0; i < icons.evaluate().length; i++)
        tester.getCenter(icons.at(i)),
    ];
  }

  testWidgets('Oyun ekranında yıldızlar maskotun yanında görünür',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    expect(await starCenters(tester, 0), isEmpty,
        reason: 'Yıldız yokken hiç simge çizilmemeli');

    expect((await starCenters(tester, 3)).length, 3);
    expect((await starCenters(tester, 10)).length, ProgressStore.maxStars);
  });

  testWidgets('Önce sol taraf dolar, sonra sağ taraf', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Maskotun yatay merkezi ~ekran ortası; 5 yıldızın tamamı solda olmalı.
    final five = await starCenters(tester, 5);
    expect(five.length, 5);
    expect(five.every((o) => o.dx < 210), isTrue,
        reason: 'İlk beş yıldız maskotun solunda olmalı: $five');

    // 6. yıldız sağa geçer: 5 sol + 1 sağ.
    final six = await starCenters(tester, 6);
    final left = six.where((o) => o.dx < 210).length;
    final right = six.where((o) => o.dx > 210).length;
    expect(left, 5, reason: 'Sol taraf dolu kalmalı');
    expect(right, 1, reason: '6. yıldız sağa geçmeli');
  });

  testWidgets('Bir yandaki beş yıldız 2 + 3 iki sıra olur', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final five = await starCenters(tester, 5);
    // Dikey konuma göre grupla: iki farklı satır olmalı.
    final rows = <double, int>{};
    for (final o in five) {
      final key = rows.keys.firstWhere(
        (k) => (k - o.dy).abs() < 4,
        orElse: () => o.dy,
      );
      rows[key] = (rows[key] ?? 0) + 1;
    }
    expect(rows.length, 2, reason: 'İki sıra olmalı: $rows');
    expect(rows.values.toList()..sort(), [2, 3],
        reason: 'Sıralar 2 ve 3 yıldız içermeli: $rows');
  });
}
