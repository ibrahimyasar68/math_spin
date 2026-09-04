import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/animal_paintings.dart';

/// Puzzle'da kullanılan bir resim: adı, zemin rengi ve çizimi.
///
/// Çizim bir [CustomPainter] üreteci olarak tutulur; ileride gerçek görsele
/// geçilmek istenirse yalnızca [painter] yerine `Image.asset` tabanlı bir
/// çizici konur, kalan kod değişmez.
class PuzzleImage {
  /// Kalıcı kayıtta kullanılan sabit kimlik. **Değiştirme** — değişirse
  /// oyuncuların yarım kalan puzzle'ı başka bir resme kayar.
  final String id;

  /// Tahmin şıklarında görünen ad.
  final String label;

  /// Resmin arkasındaki zemin rengi.
  final Color backdrop;

  /// Resmi çizen ressamı üretir.
  final CustomPainter Function() painter;

  const PuzzleImage({
    required this.id,
    required this.label,
    required this.backdrop,
    required this.painter,
  });
}

/// Oyundaki tüm puzzle resimleri.
///
/// Yeni hayvan eklemek için buraya bir satır yeter: şıklar, rastgele resim
/// seçimi ve testler hep bu listeden türer. Liste büyüdükçe tahmin de zorlaşır
/// — üç resimle kör tahminin isabet olasılığı 1/3.
const List<PuzzleImage> puzzleImages = [
  PuzzleImage(
    id: 'at',
    label: 'AT',
    backdrop: Color(0xFF7FC8E8),
    painter: HorsePainter.new,
  ),
  PuzzleImage(
    id: 'ayi',
    label: 'AYI',
    backdrop: Color(0xFF8FD6A6),
    painter: BearPainter.new,
  ),
  PuzzleImage(
    id: 'tavsan',
    label: 'TAVŞAN',
    backdrop: Color(0xFFF3C4DC),
    painter: RabbitPainter.new,
  ),
  PuzzleImage(
    id: 'kedi',
    label: 'KEDİ',
    backdrop: Color(0xFFF6D9A8),
    painter: CatPainter.new,
  ),
  PuzzleImage(
    id: 'kopek',
    label: 'KÖPEK',
    backdrop: Color(0xFF9FD4E8),
    painter: DogPainter.new,
  ),
  PuzzleImage(
    id: 'kus',
    label: 'KUŞ',
    backdrop: Color(0xFFBFD9F2),
    painter: BirdPainter.new,
  ),
  PuzzleImage(
    id: 'fil',
    label: 'FİL',
    backdrop: Color(0xFFF7D6B0),
    painter: ElephantPainter.new,
  ),
  PuzzleImage(
    id: 'aslan',
    label: 'ASLAN',
    backdrop: Color(0xFF9BD6C0),
    painter: LionPainter.new,
  ),
  PuzzleImage(
    id: 'kurbaga',
    label: 'KURBAĞA',
    backdrop: Color(0xFFCFE0F5),
    painter: FrogPainter.new,
  ),
  PuzzleImage(
    id: 'balik',
    label: 'BALIK',
    backdrop: Color(0xFF7FD3E0),
    painter: FishPainter.new,
  ),
  PuzzleImage(
    id: 'koyun',
    label: 'KOYUN',
    backdrop: Color(0xFFAFD6A8),
    painter: SheepPainter.new,
  ),
  PuzzleImage(
    id: 'tilki',
    label: 'TİLKİ',
    backdrop: Color(0xFFD8CDEC),
    painter: FoxPainter.new,
  ),
];

/// Tahmin şıkları: doğru cevap + havuzdan rastgele yanlışlar, karıştırılmış.
///
/// Şıklar havuzun tamamı değil sabit sayıda ([count]) olduğu için havuz
/// büyüdükçe tahmin zorlaşmaz; zorluk şık sayısına bağlı kalır. Her çağrıda
/// yeniden çekildiği için aynı yanlışlar tekrar gelip eleme yoluyla kolay
/// geçiş sağlamaz.
List<PuzzleImage> buildChoices(
  PuzzleImage correct, {
  int count = 4,
  Random? rng,
}) {
  final r = rng ?? Random();
  final digerleri = [
    for (final image in puzzleImages)
      if (image.id != correct.id) image,
  ]..shuffle(r);

  final secilenler = <PuzzleImage>[
    correct,
    ...digerleri.take(count - 1),
  ]..shuffle(r);
  return secilenler;
}
