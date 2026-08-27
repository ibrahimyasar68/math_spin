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

## Tam açıklama (en fazla 4000)

```
```
<!-- Console'daki mevcut tam açıklamayı buraya yapıştır -->

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
