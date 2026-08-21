import 'package:flutter/material.dart';

/// Oyunun uyumlu "candy" (şekerleme) renk paleti.
///
/// Tüm ekranlar ve bileşenler buradaki renkleri kullanır; böylece görsel
/// tutarlılık tek yerden yönetilir.
class AppColors {
  AppColors._();

  // Arka plan gece gökyüzü gradyanı (koyu tema).
  static const bgTop = Color(0xFF0E1230);
  static const bgMid = Color(0xFF241A55);
  static const bgBottom = Color(0xFF45266F);

  // Arka plan gündüz gökyüzü gradyanı (açık tema).
  // Beyaz metin okunur kalsın diye orta tonlu maviler seçildi.
  static const dayTop = Color(0xFF7EC4F2);
  static const dayMid = Color(0xFF4E96DB);
  static const dayBottom = Color(0xFF3D7EC4);

  // Ana vurgu renkleri (pastel-candy).
  static const coral = Color(0xFFFF6F91); // sıcak pembe-mercan
  static const sky = Color(0xFF5AA9E6); // yumuşak mavi
  static const mint = Color(0xFF63D6A0); // nane yeşili
  static const sunny = Color(0xFFFFC93C); // güneş sarısı
  static const grape = Color(0xFFB983FF); // üzüm moru

  // Anlamsal renkler.
  static const success = mint;
  static const danger = coral;
  static const accent = sunny;

  // Çark renkleri (soldan sağa).
  static const reelA = coral;
  static const reelOp = sky;
  static const reelB = mint;

  static const ink = Color(0xFF2A1B4D); // koyu metin (açık zeminlerde)
}
