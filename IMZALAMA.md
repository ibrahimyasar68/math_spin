# İmzalama anahtarı — yedekleme ve doğrulama

Bu dosyada **parola yok** ve olmamalı. Depoda yalnızca "ne, nerede, nasıl
doğrulanır" bilgisi durur.

## Anahtarın kimliği (gizli değil, paylaşılabilir)

| | |
|---|---|
| Dosya | `~/keyStore/mathspin-upload.jks` (2.744 bayt, 7 Temmuz 2026) |
| Alias | `upload` |
| Sahip | `CN="Ibrahim YASAR", OU=Software, O="Personal", L=Ankara, ST=Turkey, C=TR` |
| Geçerlilik | 7 Tem 2026 → 22 Kas 2053 |
| Algoritma | 2048-bit RSA, SHA256withRSA |
| SHA-1 | `1C:83:59:A8:3C:A2:76:A6:DF:0D:6E:4E:29:13:E8:DC:CF:AA:D2:DC` |
| SHA-256 | `B0:68:B5:10:6E:E0:BB:4F:45:EB:AA:32:BC:40:BB:44:2D:72:3F:25:B4:D0:22:5C:E0:73:D8:AB:12:AA:54:4F` |

**Anahtar 5 Eyl 2026'da `~/` altından `~/keyStore/` içine taşındı**; `key.properties` eski yolu gösterdiği için release yapısı "keystore bulunamadı" diye patlamıştı, yol güncellendi. Taşınan dosyanın aynı anahtar olduğu aşağıdaki SHA-256 ile doğrulandı.

Gradle bu anahtarı `android/key.properties` üzerinden bulur. O dosya
`.gitignore`'da (`key.properties`, `**/*.jks`) — depoya **hiç girmedi**,
`git ls-files` ile doğrulandı. Dosya yoksa yapı sessizce **debug** imzasına
düşer; Play böyle bir `.aab`'ı reddeder.

## Yedeklenecek dört şey

1. `~/keyStore/mathspin-upload.jks` dosyasının kendisi
2. `storePassword`
3. `keyPassword`
4. `keyAlias` (`upload`)

Parolalar olmadan `.jks` işe yaramaz; dosya olmadan parola işe yaramaz.
**İkisini birlikte, ama aynı yerde değil** saklamak en iyisi:

- **Parolalar** → parola yöneticisi (1Password / Bitwarden / Apple Şifreler),
  "MathSpin upload keystore" adıyla, not alanına alias ve SHA-256 yazılarak.
- **Dosya** → en az **iki ayrı fiziksel yer**: harici disk + ikinci bir disk
  ya da şifreli bulut klasörü. Bilgisayarın kendisi yedek sayılmaz.

Kopyalamayı sen yapmalısın; parola bende görünmesin diye komutu çalıştırmadım:

```bash
cp ~/keyStore/mathspin-upload.jks \
   /Volumes/<DISK_ADI>/mathspin-upload-$(date +%Y%m%d).jks
```

## Yedeğin sağlam olduğunu doğrulama

Kopyaladıktan sonra **kopyanın kendisini** aç — dosya bozulmadıysa parmak izi
yukarıdakiyle aynı çıkar (komut parolayı sorar, ekrana yazmaz):

```bash
keytool -list -v -keystore /Volumes/<DISK_ADI>/mathspin-upload-<TARİH>.jks -alias upload
```

Çıktıdaki SHA-256 tablodakiyle **birebir** aynı olmalı.

## Kaybedilirse ne olur

Yeni uygulamalarda **Play App Signing** zorunlu: Play'de dağıtılan APK'ları
Google'ın tuttuğu *uygulama imzalama anahtarı* imzalar, senin `.jks` ise
yalnızca **yükleme (upload) anahtarı**. Bu durumda upload anahtarı
kaybedilirse uygulama çöpe gitmez — Play Console → **Test ve yayınla → Uygulama
bütünlüğü** ekranından yeni bir upload anahtarı kaydı için Google'a başvurulur;
birkaç iş günü sürer.

Yine de: başvuru süreci sırasında güncelleme yayınlanamaz ve süreç Google'ın
onayına bağlıdır. Yedek almak hâlâ en ucuz çözüm.

> Doğrula: Play Console → Uygulama bütünlüğü ekranında "Play uygulama imzalama"
> etkin mi? Etkin **değilse** anahtarın kaybı gerçekten geri dönüşsüzdür.
