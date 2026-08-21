import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/audio_service.dart';
import 'services/progress_store.dart';
import 'services/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Dikey moda sabitle (çocuk dostu, basit deneyim).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Kayıtlı ayarları (tema, ses, ilk-açılış) yükle.
  await SettingsStore.instance.init();
  // Sesleri önceden hazırla (hata olsa bile uygulama açılır).
  await AudioService.instance.init();
  // Kayıtlı ilerlemeyi (kategori + avatar) yükle.
  await ProgressStore.instance.init();
  runApp(const MathSpinApp());
}

class MathSpinApp extends StatelessWidget {
  const MathSpinApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: brightness,
      ),
      useMaterial3: true,
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsStore.instance;
    // İlk açılışta ayar ekranıyla başla; sonraki açılışlarda ana ekran.
    final Widget firstScreen = settings.onboarded
        ? const HomeScreen()
        : const SettingsScreen(onboarding: true);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: settings.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'MathSpin',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: mode,
          home: firstScreen,
        );
      },
    );
  }
}
