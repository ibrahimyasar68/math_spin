# Google Play — Türkçe mağaza metni

Console'da yayında olan Türkçe metin bu depoya hiç yazılmamıştı; aşağıdaki
kısa açıklama bu oturumda sıfırdan yazıldı. **Uygulama adı** ve **tam açıklama**
alanları bilerek boş: Console'daki mevcut hâllerini göremediğim için buraya
uydurma bir metin koymak, yayındakiyle çelişen ikinci bir sürüm yaratırdı.
Console'dan kopyalayıp doldurulacak.

Yeri: Play Console → Büyüme → Mağaza varlığı → **Ana mağaza girişi**,
dil seçici `Türkçe (tr-TR)`. İngilizcesi için → [listing_en.md](listing_en.md).

## Uygulama adı (en fazla 30)

```
```
<!-- Console'daki mevcut adı buraya yapıştır -->

## Kısa açıklama (en fazla 80) — 69 karakter

```
Çocuklar için matematik oyunu: çarkı çevir, soruyu çöz, yıldız topla.
```

Uygulama adında "matematik" ve "çocuk" geçmediği için, Play aramasına katkı
veren bu iki kelime kısa açıklamada tutuldu. Kalan yer oyunu tek nefeste
anlatan üç fiile ayrıldı.

### Değerlendirilen alternatifler

| Karakter | Metin | Vurgu |
|---:|---|---|
| 70 | Çocuklar için reklamsız matematik: çarkı çevir, çöz, yıldızları topla. | "reklamsız" öne çıkar — ebeveyn için satın alma sebebi |
| 77 | Çarkı çevir, matematik sorusunu çöz, yıldızları topla. Reklamsız, çevrimdışı. | iki güven işareti birden, ama "çocuk" düşer |
| 72 | 40 kategori matematik. Çarkı çevir, soruyu çöz, yıldız topla. Reklamsız. | içerik hacmini gösterir |

## Tam açıklama (en fazla 4000) — 2550 karakter

Yapboz sürümüne (1.1.0) göre yeniden yazıldı; öncesindeki metin Console'da
kalmıştı, depoya hiç girmemişti.

```
MathSpin matematik alıştırmasını bir slot makinesine dönüştürür. Çocuk ÇEVİR'e basar, üç çark döner ve karşısına bir soru çıkar. Cevabı girer, konfeti patlar, sonraki soruya geçer.

NASIL OYNANIR

Her kategori 5 sorudan oluşur. 5 sorunun 4'ünü doğru bilen kategoriyi geçmeye hak kazanır. Barajı tutturamayan aynı kategoriyi baştan oynar — ilerleme geri gitmez, kaybedilen bir şey olmaz.

KATEGORİ SONUNDA YAPBOZ

Asıl sürpriz burada. Her kategoriye gizli bir hayvan resmi atanır ve resim 10 yapboz parçasına bölünür. Barajı geçen her oyun rastgele bir parçayı açar. Altta "bu hangi hayvan?" diye sorulur ve dört şık verilir. Doğru tahmin kategoriyi geçirir; yanlış tahminde çocuk aynı kategoride kalır ama açtığı parçalar durur, bir sonraki oyunda resim biraz daha görünür olur.

12 hayvan var: at, ayı, tavşan, kedi, köpek, kuş, fil, aslan, kurbağa, balık, koyun, tilki. Hepsi el çizimi, sevimli ve tanınabilir.

ZORLUK NASIL ARTIYOR

Yirmi kategori iki bölüme ayrılır. İlk on kategoride sayılar tek basamaklıdır (1-9), sonraki onda iki basamaklı (10-99). İkinci bölümde arada bilerek kolay sorular serpiştirilir, çocuk nefes alsın diye.

Bölüm içinde işlemler de kademe kademe açılır: başta yalnız toplama ve çıkarma, ortada çarpma, sonuna doğru bölme de eklenir.

Sorular iki biçimde gelir: "7 x 6 = ?" ya da "7 x ? = 42". İkincisi işlemlerin birbirini nasıl geri aldığını öğreten biçimdir.

Kurallar çocuk dostudur: bölmeler tam bölünür, kalan çıkmaz. Çıkarmada sonuç negatif olmaz. Çarpan ve bölen 2 ile 9 arasında kalır, sonuç akılda tutulabilir olsun diye.

ÖDÜLLER

Geçilen her kategoride yaş pasta ekranı gelir; çocuk o ana kadar geçtiği kategori sayısı kadar mumu parmağıyla üfleyerek söndürür. Yirmi kategorinin hepsi bitince 10 mumlu final pastası ve taçlı maskotun olduğu şampiyonluk ekranı açılır.

Her bitiriş bir yıldız kazandırır. Yıldızlar kalıcıdır; baştan başlamak kazanılanı geri almaz. Onuncu yıldızda oyun tamamen biter.

EBEVEYNLER İÇİN

• Reklam yok. Uygulama içi satın alma yok. Satılan hiçbir şey yok.
• Hesap yok, giriş yok, kişisel veri toplanmıyor.
• İnternet gerekmez — uygulama internet iznini bile istemiyor. Uçakta da arabada da aynı şekilde çalışır.
• Beş farklı karakter, açık ve koyu tema, tek dokunuşla kapatılabilen ses.
• Büyük düğmeler, sade rakam tuş takımı, küçük telefonlarda da okunaklı yazılar.

KİMLER İÇİN

6-12 yaş arası, toplama, çıkarma, çarpma ve bölmeyle uğraşan her çocuk. Küçükler ilk on kategoride tek basamaklı sayılarla kalabilir; büyükler iki basamaklı bölümde gerçek bir sınavla karşılaşır.
```

## Karakter sayımı

```bash
python3 - <<'PY'
import re, pathlib
t = pathlib.Path('store/listing_tr.md').read_text()
blocks = re.findall(r'```\n(.*?)```', t, re.S)
for name, b, lim in zip(['ad', 'kısa açıklama', 'tam açıklama'], blocks, [30, 80, 4000]):
    b = b.strip()
    durum = 'BOŞ' if not b else ('OK' if len(b) <= lim else 'UZUN!')
    print('%-14s %4d / %d  %s' % (name, len(b), lim, durum))
PY
```
