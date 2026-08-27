"""MathSpin ikonundaki 'kart' izini temizler.

Kaynak gorselde cizimin arkasinda, tuvalden biraz daha acik, yuvarlak koseli
bir panel var. Bu panel iki iz birakiyor:
  1) dort kosede ~30 birim koyulukta 2-3 px'lik keskin yay,
  2) panelin kendi sinirindaki aydinlik basamagi (asil 'cerceve' hissi).

Adim 1: yaylar, buyuk yaricapli medyanla (arka planin puruzsuz tahmini)
        degistirilir; serit/kontur gibi gercek cizim 8 px payla korunur.
Adim 2: cizim maskelenip arka plan alani doldurulur, cok genis Gauss ile
        tam sayfaya yayilan yumusak isiga cevrilir; olusan *duzeltme farki*
        tum goruntuye eklenir. Fark puruzsuz oldugu icin dikis izi olusmaz.

Kullanim: python3 ikon_duzelt.py <girdi.png> <cikti.png>
"""
from PIL import Image, ImageFilter
import numpy as np, sys

def box1d(a, r, axis):
    if r < 1:
        return a
    a = np.moveaxis(a, axis, 0)
    p = np.pad(a, [(r + 1, r)] + [(0, 0)] * (a.ndim - 1), mode='edge')
    c = np.cumsum(p, axis=0)
    out = (c[2 * r + 1:] - c[:-(2 * r + 1)]) / (2 * r + 1)
    return np.moveaxis(out, 0, axis)

def gblur(a, sigma):
    """3 kutu gecisiyle Gauss yaklasimi; kenarlar replike edilir."""
    r = max(1, int(round(sigma)))
    for _ in range(3):
        a = box1d(a, r, 0)
        a = box1d(a, r, 1)
    return a

SIGMA = 110.0

def dilate(mask, size):
    return np.asarray(Image.fromarray((mask * 255).astype(np.uint8))
                      .filter(ImageFilter.MaxFilter(size))) > 0

def arklari_temizle(A):
    """Kosedeki keskin koyu yaylari sil."""
    img   = Image.fromarray(A.astype(np.uint8))
    med15 = np.asarray(img.filter(ImageFilter.MedianFilter(15))).astype(np.float64)
    med31 = np.asarray(img.filter(ImageFilter.MedianFilter(31))).astype(np.float64)
    diff  = (med15 - A).max(axis=2)                    # pozitif = orijinal daha koyu

    bluish = (A[:, :, 2] > 200) & (A[:, :, 1] > 150)
    art    = dilate((diff > 55) | (~bluish), 17)       # serit + konturlar, 8 px pay

    h, w = diff.shape
    inbox = np.zeros((h, w), bool)
    for x0, x1, y0, y1 in [(100, 230, 100, 230), (794, 924, 100, 230),
                           (100, 230, 794, 924), (794, 924, 794, 924)]:
        inbox[y0:y1, x0:x1] = True

    mask = (diff > 2.5) & ~art & inbox
    m = Image.fromarray((mask * 255).astype(np.uint8))
    m = m.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(2.0))
    mf = np.asarray(m).astype(np.float64) / 255.0
    mf = np.where(inbox, mf, 0.0)[:, :, None]
    print('  yay pikseli:', int(mask.sum()))
    return A * (1 - mf) + med31 * mf

def paneli_duzle(A):
    """Panel basamagini tam sayfa yumusak isiga cevir."""
    R, G, B = A[:, :, 0], A[:, :, 1], A[:, :, 2]
    bg  = (B > 238) & (G > 182) & (G - R > 45) & (G - R < 110)
    art = dilate(~bg, 9)
    keep = (~art).astype(np.float64)
    print('  arka plan orani: %%%.1f' % (100 * keep.mean()))

    num    = gblur(A * keep[:, :, None], 60.0)
    den    = gblur(keep, 60.0)[:, :, None] + 1e-6
    filled = np.where(art[:, :, None], num / den, A)
    flat   = gblur(filled, SIGMA)
    delta  = flat - filled
    print('  duzeltme araligi: %.1f .. %.1f' % (delta.min(), delta.max()))
    return np.clip(A + delta, 0, 255)

src, out = sys.argv[1], sys.argv[2]
im = Image.open(src)
A  = np.asarray(im.convert('RGB')).astype(np.float64)
print(src, '->', out)
A = arklari_temizle(A)
A = paneli_duzle(A)
res = Image.fromarray((A + 0.5).astype(np.uint8))
if im.mode == 'RGBA':
    res = res.convert('RGBA'); res.putalpha(im.getchannel('A'))
res.save(out)
print('  yazildi:', out, res.mode, res.size)
