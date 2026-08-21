# MathSpin 🎰 – Çocuklar için Matematik Oyunu

10 yaşından küçük çocuklar için slot makinesi temalı, eğlenceli bir matematik
alıştırma oyunu. Çocuk "ÇEVİR" butonuna basar, çarklar döner ve karşısına bir
matematik sorusu çıkar.

## Özellikler

- **20 soruluk oyun**, kademeli zorluk artışıyla:
  - Soru 1–5: Toplama (1–10)
  - Soru 6–10: Çıkarma (sonuç her zaman pozitif)
  - Soru 11–15: Çarpma (1–5 × 1–5)
  - Soru 16–20: Karışık (+ − × ÷, bölmeler tam sayı)
- Her soruda ya sonuç ya da bir operand bilinmiyor (rastgele).
- 3 adet **slot makinesi çarkı**, dikey kayan animasyonla sırayla durur.
- **Doğru cevap:** konfeti + alkış sesi + yeşil parlama, 1 sn sonra sonraki soru.
- **Yanlış cevap:** titreşim + hata sesi + kırmızı parlama; 3 yanlışta doğru
  cevap gösterilir.
- **Sonuç ekranı:** puana göre emoji/mesaj, doğru-yanlış sayıları ve soru özeti.
- Yıldızlı gece gökyüzü teması, büyük çocuk dostu butonlar, Google Fonts
  (Fredoka & Nunito).

## Proje yapısı

```
lib/
  main.dart                      # Uygulama girişi, tema
  screens/
    home_screen.dart             # Açılış / ana menü
    game_screen.dart             # Oyun akışı, çarklar, klavye
    result_screen.dart           # Sonuç özeti
  widgets/
    slot_reel.dart               # Slot çarkı + SlotReelController
    confetti_overlay.dart        # Konfeti katmanı
    starry_background.dart       # Animasyonlu yıldızlı arka plan
  models/
    question.dart                # Question, MathOp, QuestionResult
  services/
    audio_service.dart           # Ses efekt yönetimi (audioplayers)
    question_generator.dart      # Soru üretimi
assets/sounds/
  clap.mp3, wrong.mp3            # Yer tutucu (README'ye bakın)
```

## Çalıştırma

```bash
flutter pub get
flutter run         # bağlı bir cihaz veya emülatör seçin
```

Testler:

```bash
flutter analyze
flutter test
```

## Ses dosyaları

`assets/sounds/clap.mp3` ve `wrong.mp3` şu an **boş yer tutuculardır**.
Gerçek ses için bunları kendi telifsiz `.mp3` dosyalarınızla değiştirin —
detaylar `assets/sounds/README.md` içinde. Ses olmadan da oyun çökmeden çalışır.

## Bağımlılıklar

- [`google_fonts`](https://pub.dev/packages/google_fonts) – Fredoka & Nunito
- [`confetti`](https://pub.dev/packages/confetti) – konfeti efekti
- [`audioplayers`](https://pub.dev/packages/audioplayers) – ses efektleri
