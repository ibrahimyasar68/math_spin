# Buradan devam — MathSpin (Flutter çocuk matematik oyunu)

Proje dizini: `/Users/ibrahimyasar/Desktop/mathSpin`
Depo: https://github.com/ibrahimyasar68/math_spin (main ile senkron)
Flutter 3.35.6, null-safe, setState tabanlı. `flutter analyze` temiz, **43 test geçiyor**.

## Yapı

```
lib/main.dart
screens/  home, game, result, settings, cake_celebration, victory
widgets/  slot_reel, confetti_overlay, starry_background, candy_button,
          feedback_badge, mascot, avatar_picker, puzzle_panel, puzzle_board,
          animal_paintings (12 hayvan)
models/   question.dart, puzzle_image.dart
services/ audio_service, question_generator, avatar_store, progress_store,
          settings_store, puzzle_store
assets/   icon/, sounds/ (clap, wrong, spin), google_fonts/ (Baloo2 + Nunito)
privacy/index.html   -> GitHub Pages ile yayında
store/listing_en.md  -> İngilizce mağaza metni (kopyala-yapıştır hazır)
store/listing_tr.md  -> Türkçe kısa açıklama (ad + tam açıklama Console'dan
                        doldurulacak)
tools/ikon_duzelt.py -> ikon kart izini temizleyen betik
IMZALAMA.md          -> anahtar yedekleme ve doğrulama (parola içermez)
test/     10 dosya
```

## Oyun planı sürümleri

**Yürürlükteki plan: 2 bloklu.** 28 Ağu 2026'da 3 ve 4 basamaklı bantlar
(eski kategori 21–40) plandan çıkarıldı; kod da aynı gün buna göre değişti.
4 bloklu sürüm aşağıda arşiv olarak duruyor — geri dönülmek istenirse
`bandCount` ve `_band` oradaki değerlere döner.

## Oyun mekaniği — 4 BLOKLU SÜRÜM (arşiv, 28 Ağu 2026'ya kadar yürürlükteydi)

> Bu plan **artık uygulanmıyor**; kod 2 bloklu sürümü çalıştırıyor. Aşağıdaki
> tablo yalnızca kayıt amaçlı duruyor.
> Görsel çizelge (4 bloklu): https://claude.ai/code/artifact/17f88b95-ef57-41b1-aa00-7c9798e97359

**40 kategori**, 15'lik değil **10'luk 4 bant**. Toplam **340 soru**.

| Sıra | Soru | İşlemler | Blok 1 | Blok 2 | Blok 3 | Blok 4 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1-3 | 10 | + − | K1-3 | K11-13 | K21-23 | K31-33 |
| 4-5 | 10 | + − × | K4-5 | K14-15 | K24-25 | K34-35 |
| 6 | 9 | + − × ÷ | K6 | K16 | K26 | K36 |
| 7 | 8 | + − × ÷ | K7 | K17 | K27 | K37 |
| 8 | 7 | + − × ÷ | K8 | K18 | K28 | K38 |
| 9 | 6 | + − × ÷ | K9 | K19 | K29 | K39 |
| 10 | 5 | + − × ÷ | K10 | K20 | K30 | K40 |

Basamaklar: Blok 1 (K1-10) 1 basamak · Blok 2 (K11-20) 2 · Blok 3 (K21-30) 3
(+%10 oranında 1-2 basamaklı karışım) · Blok 4 (K31-40) 4 (+%15 oranında 1-3).

- **Puanlama yüzde**: doğru/toplam × 100, baraj **%80**. (Sabit "10 puan" kuralı
  soru adedi düşünce çalışmıyordu; 7 soruluk kategoride baraj asla geçilemezdi.)
- Barajın yan etkisi: hata hakkı soru adedine bağlı. Sırası 1-5 olan
  kategorilerde 10 soruda **2** yanlış hakkı var; 6. sıradan itibaren
  **tek yanlış** hakkı kalıyor (9/8/7/6/5 soruda sırasıyla 8/7/6/5/4 doğru
  gerekiyor). Yani bandın sonu hem işlem hem tolerans olarak sertleşiyor.
- Karışım kararı **soru başına** verilir — sayı başına verilseydi çıkarmadaki
  `a >= b` takası oranı bozardı.
- Çarpan/bölen 2-9; bölmeler tam bölünür; çıkarmada sonuç negatif olmaz.
- Soru iki biçimde gelir: `A op B = ?` veya `A op ? = C`.

## Oyun mekaniği — 2 BLOKLU SÜRÜM (yürürlükte, 28 Ağu 2026'dan beri)

**20 kategori**, 10'luk **2 bant**. Her kategoride **5 soru**, toplam
**100 soru** (bant başına 50).

Soru adedi eskiden bant içinde 10'dan 5'e kademeli azalıyordu; **28 Ağu 2026'da
kaldırıldı** — her kategori aynı uzunlukta, tek değişen zorluk.

| Sıra | Soru | Geçmek için | Hata hakkı | İşlemler | Blok 1 | Blok 2 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1-3 | 5 | 4 | 1 | + − | K1-3 | K11-13 |
| 4-5 | 5 | 4 | 1 | + − × | K4-5 | K14-15 |
| 6-10 | 5 | 4 | 1 | + − × ÷ | K6-10 | K16-20 |

**Barajın anlamı değişti:** 5 soruda %80 = 4 doğru, yani **her kategoride tek
yanlış hakkı** var. Eskiden bandın ilk beş kategorisinde 10 soruda 2 yanlış
hakkı vardı; artık baştan sona tek. İstenirse baraj `ResultScreen._passScore`
ile gevşetilir (%60 → 3 doğru yeter).

Görsel çizelge (2 bloklu):
https://claude.ai/code/artifact/bf3c4962-654a-4482-a585-f0fa0bae287c

Basamaklar: **Blok 1 (K1-10) 1 basamak (1-9)** · **Blok 2 (K11-20) 2 basamak
(10-99), %5 oranında tek basamaklı karışım**. Blok 1'de karışım yok ve
olamaz — 1 basamağın altına inilecek aralık yok, `_operandRange` içindeki
`digits > 1` koşulu o bandı zaten dışarıda bırakır. Oran düşük tutuldu: amaç
zorluğu seyreltmek değil, iki basamaklı sorularda tekdüzeliği kırmak.

Değişmeyenler: yüzde puanlama ve %80 barajı, iki soru biçimi (`A op B = ?` / `A op ? = C`), çarpan-bölen 2-9, tam bölünen
bölmeler, negatif olmayan çıkarma.

**Geçiş notu:** `ProgressStore.init` kayıtlı kategoriyi `1..maxCategory`
aralığına kırptığı için, eski sürümde 21+ kategoriye gelmiş test cihazları
açılışta sessizce **K20'ye** düşer. Ayrı bir göç kodu gerekmedi.

## Yapboz — kategori geçişi (28 Ağu 2026)

Kategori **matematik puanıyla geçilmiyor**. Her kategoriye 12 hayvandan biri
atanır, resim **10 gerçek yapboz parçasına** bölünür ve kapalı durur.

| Olay | Sonuç |
|---|---|
| Puan **≥ %80** | Rastgele **bir parça açılır** + **4 şık** sorulur (doğru + 3 rastgele yanlış) |
| Puan **< %80** | **Yapboz hiç gösterilmez**: "BAŞARISIZ" notu, kategori baştan tekrar edilir |
| Tahmin **doğru** | Kategori geçilir → pasta → sonraki kategori |
| Tahmin **yanlış** | Kategori aynı kalır, açık parçalar korunur |

Akış: oyun → **sonuç ekranı (yapboz içinde)** → oyun. Yapbozun ayrı ekranı yok;
iki oyun arasında tek durak olsun diye sonuç ekranının gövdesine kondu
(`widgets/puzzle_panel.dart`). Yer açmak için soru soru özet listesi yerini
✓/✗ rozet şeridine bıraktı.

**İlk sürümde oturmayan dört şey ve çözümleri** (hepsi bu revizyonda):

1. *Tahmin çok kolaydı* — 3 resim vardı ve şıklar hep aynı üçüydü. Havuz
   **12 hayvana** çıktı ve şıklar havuzun tamamı değil **4 tane**; kör tahminde
   isabet 1/3'ten 1/4'e indi, ezberleme yolu kapandı.
2. *Akış uzundu* — ayrı yapboz ekranı kaldırıldı (yukarıya bak).
3. *Baraj altında tahmin yoktu* — önce kaldırıldı (her oyundan sonra tahmin),
   sonra **28 Ağu 2026'da geri alındı ve sertleştirildi**: baraj altında yapboz
   hiç açılmıyor, ekran "BAŞARISIZ" diyor ve kategori baştan tekrar ediliyor.
   Böylece rastgele şıkka basarak ilerleme yolu tamamen kapandı; matematik
   yeniden zorunlu.
4. *Görünüş* — düz dikdörtgen ızgara yerine **tırtıklı yapboz parçaları**.

Teknik notlar:

- Parça yolları `widgets/puzzle_board.dart`. Kenar tırtığı t=0.5 ekseninde
  **simetrik** çizildiği için kenar ters yönde taransa da aynı eğri çıkar;
  komşu iki parça bu sayede boşluksuz ve çakışmasız oturur. `puzzle_test.dart`
  bunu `Path.combine` ile kanıtlıyor (birleşim = tahta, kesişim ≈ 0).
- Kenar yönleri resmin `id`'sinden türeyen sabit tohumla belirlenir: aynı resim
  her açılışta aynı biçimde bölünür.
- Tahta tek `CustomPaint`; tırtıklar komşu hücreye taştığı için parça başına
  ayrı kutu (Positioned + ClipRect) yetmiyordu.
- Resimler kodda **vektör** çiziliyor (`widgets/animal_paintings.dart`), asset
  yok. Yeni hayvan eklemek: bir `AnimalPainter` alt sınıfı + `puzzle_image.dart`
  listesine bir satır. Şıklar ve rastgele seçim kendiliğinden uyar.
- `PuzzleStore` kategoriyi **dinler**: kategori hangi sebeple değişirse değişsin
  parçalar kapanır, önceki resimden farklı yeni bir resim atanır.
- Kalıcı: `puzzle.imageIndex`, `puzzle.revealedMask` (10 bitlik maske).

## Bitirme senaryosu ve yıldızlar

- K20'de resim doğru bilinince: **10 mumlu final pastası**
  → **zafer ekranı** (taçlı maskot, "ŞAMPİYON!", 20/100/2 özeti, konfeti+alkış).
  Özetteki üç sayı da koddan türer (`maxCategory`, soru toplamı, `bandCount`).
- Her bitiriş **1 yıldız**. Yıldızlar kalıcı; baştan başlamak geri almaz.
- **Ana ekranda** avatarın iki yanında tek sütun, dengeli dağılım
  (1. sağa, 2. sola...) → 10'da 5 sağ / 5 sol.
- **Oyun ekranında** maskotun yanında **2+3 iki sıra**, **önce sol taraf** dolar.
- **10. yıldızda oyun tamamen biter**: ekran "OYUN BİTTİ!" olur, "Baştan başla"
  sunulmaz, yalnızca son kategori tekrar oynanabilir.

## Diğer güncel davranışlar

- **Ayarlar** (sağ üst dişli, ana ekran + oyun ekranı): tema (sistem/açık/koyu),
  ses aç-kapa, avatar (5 adet). İlk açılışta onboarding olarak gelir.
- **Cevap alanı sabit yükseklikte** (`_AnswerPad.totalHeight`); soru çerçevesi
  fazlar arasında ne kayar ne boyut değiştirir.
- **ÇEVİR ile TAMAM birebir aynı dikdörtgende** (28 Ağu 2026): ÇEVİR alanın
  tamamını kaplayıp alta hizalanır ve TAMAM'ın ölçülerini alır
  (`submitHeight`, fontSize 26). Çocuk fazlar arasında parmağını taşımıyor.
  `frame_stability_test.dart` iki dikdörtgenin eşitliğini kilitliyor.
- Kalan kısa içerik (doğru-cevap kartı, "Çevriliyor...") boşluğun **1/5'i kadar
  yukarıda** durur (`Alignment(0, 0.6)`).
- **Fontlar gömülü** (`assets/google_fonts/`): Baloo2 (başlık) + Nunito (gövde).
  `GoogleFonts.config.allowRuntimeFetching = false`. Fredoka kullanılmıyor —
  Türkçe **ğ Ğ ş Ş İ** harfleri yok.
- **Çark sesi** (`assets/sounds/spin.m4a`): ÇEVİR'e basınca çalar. Tık zamanları
  `Curves.easeOutCubic`'ten türetilir, görselle senkron yavaşlar. v4 ayarı:
  perde 1500→200 Hz, 15 tık, RMS 0.055. Ses kapalıyken çalmaz; ekrandan
  çıkılınca durur.
- Çok basamaklı sayılar için taşma koruması (FittedBox + maxLines:1) çark
  hücresi, sonuç kutusu, doğru-cevap kartı ve sonuç listesinde.

## Android / yayın yapılandırması

- `applicationId` / namespace: **com.iylabs.mathspin** (kalıcı, değiştirilemez)
- Uygulama adı: **MathSpin** · versionCode **3**, versionName **1.1.0**
  (Play'deki kapalı test sürümü hâlâ versionCode 2 — 40 kategori/340 soru,
  yapbozsuz, eski ikonlu. Bu oturumun hiçbir değişikliği orada yok.)
- İmzalama: `android/key.properties` → `~/mathspin-upload.jks` (alias `upload`).
  Gradle key.properties yoksa debug'a düşer. `.aab` upload anahtarıyla imzalı
  olduğu doğrulandı (CN="Ibrahim YASAR").
- **INTERNET izni YOK** — uygulama tamamen çevrimdışı.
- Yüklenecek paket:
  `build/app/outputs/bundle/release/app-release.aab` (42.1 MB)

## Google Play Console durumu

**Tamamlananlar**
- Uygulama oluşturuldu (Oyun, Ücretsiz)
- Gizlilik politikası yayında ve doğrulandı:
  https://ibrahimyasar68.github.io/math_spin/privacy/
- App content beyanlarının **tamamı**: uygulama erişimi, reklamlar (yok),
  içerik derecelendirmesi (3+), hedef kitle (6-8 / 9-12, Families Policy),
  veri güvenliği (**veri toplanmıyor**), kısa beyanlar
- Mağaza görselleri: ikon, feature graphic (1024×500),
  **5 telefon ekran görüntüsü** (`store_assets/`, git'te değil)
- Kısa + tam açıklama **(ESKİ: 40 kategori/340 soru anlatıyor, yapbozdan
  söz etmiyor — aşağıdaki toplu güncellemede yenilenecek)**
- **`.aab` kapalı teste yüklendi**

**Sırada**
1. **Test kullanıcıları** — kişisel hesap olduğu için **12+ testçi × kesintisiz
   14 gün** şartı. Sayaç, kişiler **katılımı onaylayınca** başlar; listeye
   eklenmek yetmez. 15-18 kişi eklenmesi önerildi (tampon).
2. 14 gün dolunca **Production**'a başvuru.

## Play sürüm güncellemesi — TOPLU YAPILACAK

Karar: mağaza tarafı **parça parça değil, tek seferde** güncellenecek. Kodda
biriken değişiklikler (2 bloklu plan, yapboz, ÇEVİR konumu, ikon) Play'de
yayınlanmadı; aşağıdakiler o gün topluca yapılacak. **İstenmeden başlanmayacak.**

Yapılacaklar listesi:

1. **Sürüm numarası** — `pubspec.yaml` `1.0.0+2` → en az `+3`. Kullanıcıdaki
   başlatıcı ikonu ve yapboz ancak yeni `.aab` ile gider.
2. **`.aab` üretimi ana dizinde** — `flutter build appbundle --release`.
   Worktree'de `android/key.properties` olmadığı için oradan alınan yapı
   sessizce debug'a düşer ve Play reddeder.
3. **Türkçe mağaza metni** (Console → Ana mağaza girişi). Mevcut metin 40
   kategori/340 soru diyor; doğrusu **20 kategori / 100 soru**. Yapbozdan hiç
   söz etmiyor. Güncellenen metin `store/listing_tr.md`'ye de yazılsın ki
   geçmişi git'te dursun.
4. **İngilizce metin** — `store/listing_en.md` aynı iki sebeple eski; oradaki
   sayılar ve içerik yenilenmeli. (Arayüz Türkçe olduğunu söyleyen paragraf
   arayüz yerelleştirilmediyse kalsın.)
5. **Ekran görüntüleri** — 5 telefon görüntüsü artık oyunu yansıtmıyor: sonuç
   ekranı baştan tasarlandı, yapboz eklendi. Yeniden çekilmeli
   (`store_assets/`, git'te değil).
6. **Sürüm notları** ("Yenilikler") — yapboz, 12 hayvan, yeni sonuç ekranı,
   ÇEVİR konumu, ikon rötuşu.
7. Feature graphic ve app content beyanları değişmiyor; 512×512 ikon zaten
   yüklendi.

**Yapılmayı bekleyen (opsiyonel)**
- 🔑 **Keystore yedeği** — dosyayı harici diske kopyalamak ve parolayı parola
  yöneticisine yazmak **hâlâ yapılmadı**; adımlar ve doğrulama komutu
  `IMZALAMA.md`'de. Not: Play App Signing etkinse kayıp geri dönüşsüz değil,
  upload anahtarı Google'a başvuruyla yenilenebilir (birkaç iş günü) —
  Play Console → Uygulama bütünlüğü ekranından teyit et.
- ~~İngilizce mağaza metni~~ → `store/listing_en.md` hazır. Uygulama arayüzü
  Türkçe olduğu için metnin sonunda bunu söyleyen bir paragraf var; arayüz
  yerelleştirilirse o paragraf silinmeli.
- ~~İkonun iç kısmındaki soluk çerçeve izi~~ → **düzeltildi** (aşağıya bak).

## İkon (28 Ağu 2026'da düzeltildi)

Kaynak görselde çizimin arkasında, tuvalden biraz daha açık, yuvarlak köşeli
bir panel vardı. İki iz bırakıyordu: dört köşede ~30 birim koyulukta 2-3 px'lik
keskin yay, ve panelin kendi aydınlık basamağı (asıl "çerçeve" hissi).
`tools/ikon_duzelt.py` önce yayları büyük yarıçaplı medyanla siliyor, sonra
çizimi maskeleyip arka plan alanını çok geniş Gauss ile tam sayfaya yayılan
yumuşak ışığa çeviriyor; oluşan düzeltme farkı bütün görüntüye ekleniyor, bu
yüzden dikiş izi olmuyor. `assets/icon/` içindeki iki PNG de işlendi, sonra:

```bash
dart run flutter_launcher_icons     # mipmap + ios ikonlarını yeniden üretir
```

Betik kaynaktan **birebir tekrar üretilebilir** (aynı SHA-1). Bir kez çalışır,
çıktısına ikinci kez uygulanmamalı.

- Play mağaza ikonu için 512×512 sürüm: `store_assets/store_icon_512.png`
  (git'te değil). **28 Ağu 2026'da Console'a yüklendi**, Google incelemesi
  onaylayana kadar mağazada eski simge görünür.
- Kullanıcıların telefonundaki başlatıcı ikonunun değişmesi için **versionCode
  3 + yeni `.aab`** gerekir; sadece asset değişmesi yetmez.

## Oturumda öğrenilen tuzaklar

- **`adb install` sessizce başarısız olabiliyor** (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`
  — cihazda debug imzalı eski sürüm kalırsa). `tail -1` ile çıktı kırpılırsa fark
  edilmez ve eski yapı test edilir. Bu oturumda 3 kez oldu. Çözüm: `uninstall`
  + `install`, sonra **APK içindeki dosyanın hash'ini yereldekiyle karşılaştır**.
- Emülatörde prefs dosyası ancak uygulama bir kez çalıştıktan sonra oluşur;
  kategori/yıldız ayarlamak için önce onboarding'i geçmek gerekiyor.
- **Emülatörde test etmeden önce main'e merge et.** Worktree'deki commit'siz
  değişiklikler ana dizine yansımaz; oradan alınan yapı eski kodu içerir.
  Bu oturumda iki kez yaşandı (ÇEVİR konumu ve 5 soruluk kategori "değişmemiş"
  göründü). Kural: **commit → merge → build**, sırasıyla.
- **Worktree'de `android/key.properties` yok** (gitignore'da). Worktree içinde
  `flutter build appbundle --release` çalıştırılırsa yapı sessizce **debug**
  imzasına düşer ve Play reddeder. Yayın yapıları ana dizinde alınmalı.
- `README.md` güncel değil: 20 soruluk eski sürümü ve Fredoka'yı anlatıyor.
- Oyun ekranı koordinatları (1080×2400 emülatör): klavye satırları
  y≈1537/1710/1880/2050, sütunlar x≈207/540/872, **TAMAM ve ÇEVİR aynı yerde:
  y≈2245** (ÇEVİR eskiden 2040'taydı, aynı hizaya alındı).

## Komutlar

```bash
flutter analyze && flutter test
flutter build apk --release      # emülatör testi
flutter build appbundle --release # Play yüklemesi
```
