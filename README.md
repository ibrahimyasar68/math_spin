# MathSpin 🎰 – Çocuklar için Matematik Oyunu

6-12 yaş çocuklar için slot makinesi temalı bir matematik alıştırma oyunu.
Çocuk **ÇEVİR**'e basar, üç çark döner ve karşısına bir soru çıkar. Kategori
sonunda, doğru cevaplarla açılan bir hayvan yapbozunu tahmin ederek bir üst
kategoriye geçer.

Reklam yok, uygulama içi satın alma yok, hesap yok. **INTERNET izni bile
istenmiyor** — oyun tamamen çevrimdışı çalışır.

## Oyun planı

**20 kategori**, 10'luk **2 bant**. Her kategoride **5 soru**, toplam **100**.

| | Blok 1 (K1-10) | Blok 2 (K11-20) |
|---|---|---|
| Basamak | 1 (1-9) | 2 (10-99), %5 tek basamaklı karışım |

İşlemler bant içinde kademe kademe açılır: 1-3. sırada `+ −`, 4-5'te `+ − ×`,
6-10'da dört işlem. Sorular iki biçimde gelir: `7 × 6 = ?` ya da `7 × ? = 42`.
Bölmeler tam bölünür, çıkarmada sonuç negatif olmaz, çarpan/bölen 2-9.

**Geçiş:** puan yüzde hesaplanır (doğru/toplam × 100), baraj **%80** — 5 soruda
4 doğru, yani tek yanlış hakkı. Baraj geçilirse yapbozdan rastgele bir parça
açılır ve "bu hangi hayvan?" diye sorulur (12 hayvandan 4 şık). **Kategoriyi
geçiren şey doğru tahmin**; baraj altında yapboz hiç gösterilmez, kategori
başarısız sayılıp baştan tekrar edilir.

**Ödüller:** geçilen her kategoride mum üfleme, K20'de 10 mumlu final pastası
ve şampiyonluk ekranı. Her bitiriş 1 yıldız, 10 yıldızda oyun tamamen biter.

## Proje yapısı

```
lib/
  main.dart
  models/      question.dart, puzzle_image.dart (12 hayvanlık havuz)
  screens/     home, game, result (yapboz burada), settings,
               cake_celebration, victory
  services/    question_generator, progress_store, puzzle_store,
               audio_service, avatar_store, settings_store
  widgets/     slot_reel, puzzle_board (tırtıklı parçalar),
               puzzle_panel, animal_paintings (12 hayvan çizimi),
               candy_button, mascot, confetti_overlay, starry_background,
               feedback_badge, avatar_picker
  theme/       app_colors.dart
assets/        icon/, sounds/, google_fonts/ (Baloo2 + Nunito, gömülü)
test/          10 dosya
```

Yazı tipleri uygulamaya gömülüdür, çalışma anında indirilmez. Hayvan çizimleri
de görsel dosya değil, `CustomPainter` ile kodda çizilir — yeni hayvan eklemek
`puzzle_image.dart` listesine bir satır.

## Komutlar

```bash
flutter analyze && flutter test
flutter build apk --release        # emülatör testi
flutter build appbundle --release  # Play yüklemesi
```

Release yapıları **ana dizinde** alınmalı: imzalama `android/key.properties`
üzerinden yapılır ve o dosya git'te değildir, worktree'lerde bulunmaz.

## Diğer belgeler

- [DEVAM.md](DEVAM.md) — güncel durum, karar gerekçeleri, Play Console durumu
  ve oturumlarda öğrenilen tuzaklar
- [IMZALAMA.md](IMZALAMA.md) — imzalama anahtarının yedeklenmesi ve doğrulanması
- [store/](store/) — mağaza metinleri (TR ve EN)
