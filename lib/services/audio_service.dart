import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'settings_store.dart';

/// Oyun ses efektlerini yöneten basit servis.
///
/// Ses dosyaları `assets/sounds/` altında bulunur. audioplayers'ın
/// [AssetSource] yolu pubspec'teki `assets/` ön ekine göre verilir,
/// yani burada yalnızca "sounds/clap.m4a" yazmak yeterlidir.
class AudioService {
  AudioService._internal();

  static final AudioService instance = AudioService._internal();

  // Her efekt için ayrı oynatıcı: üst üste/çakışan çalmalarda sorun çıkmaz.
  final AudioPlayer _clapPlayer = AudioPlayer();
  final AudioPlayer _wrongPlayer = AudioPlayer();

  bool _initialized = false;

  /// Oynatıcıları düşük gecikmeli mod için hazırlar.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _clapPlayer.setReleaseMode(ReleaseMode.stop);
      await _wrongPlayer.setReleaseMode(ReleaseMode.stop);
      // Önceden yükleyerek ilk çalmadaki gecikmeyi azaltırız.
      await _clapPlayer.setSource(AssetSource('sounds/clap.m4a'));
      await _wrongPlayer.setSource(AssetSource('sounds/wrong.m4a'));
    } catch (e) {
      // Asset henüz eklenmemişse uygulamanın çökmemesi için yutuyoruz.
      debugPrint('AudioService init hatası: $e');
    }
  }

  Future<void> playClap() => _safePlay(_clapPlayer, 'sounds/clap.m4a');

  Future<void> playWrong() => _safePlay(_wrongPlayer, 'sounds/wrong.m4a');

  Future<void> _safePlay(AudioPlayer player, String asset) async {
    // Kullanıcı sesi kapattıysa hiç çalma.
    if (!SettingsStore.instance.soundEnabled.value) return;
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('Ses çalınamadı ($asset): $e');
    }
  }

  Future<void> dispose() async {
    await _clapPlayer.dispose();
    await _wrongPlayer.dispose();
  }
}
