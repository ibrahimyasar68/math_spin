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
];
