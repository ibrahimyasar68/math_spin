import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/puzzle_image.dart';
import '../services/audio_service.dart';
import '../services/puzzle_store.dart';
import '../theme/app_colors.dart';
import 'candy_button.dart';
import 'puzzle_board.dart';

/// Sonuç ekranının içindeki yapboz bölümü: tahta, parça sayacı ve tahmin
/// şıkları.
///
/// Ayrı bir ekran değil — oyun ile sonraki oyun arasına fazladan bir durak
/// koymamak için sonuç ekranının gövdesinde durur. Tahmin yapılınca kısa bir
/// geri bildirimin ardından [onGuessed] çağrılır; yönlendirme kararı (kategori
/// geçişi, pasta, oyuna dönüş) sonuç ekranına aittir.
class PuzzlePanel extends StatefulWidget {
  /// Bu turda açılan parça (baraj geçilmediyse `null`) — animasyonla girer.
  final int? newPiece;

  /// Tahminin ardından çağrılır; parametre doğru bilinip bilinmediğidir.
  final ValueChanged<bool> onGuessed;

  const PuzzlePanel({
    super.key,
    required this.newPiece,
    required this.onGuessed,
  });

  @override
  State<PuzzlePanel> createState() => _PuzzlePanelState();
}

class _PuzzlePanelState extends State<PuzzlePanel> {
  /// Şıklar bir kez çekilir; ekran her yeniden çizildiğinde değişmemeli.
  late final List<PuzzleImage> _choices;

  PuzzleImage? _picked;
  bool _bildirildi = false;

  bool get _correct => _picked?.id == PuzzleStore.instance.image.id;

  @override
  void initState() {
    super.initState();
    _choices = buildChoices(PuzzleStore.instance.image, rng: Random());
  }

  void _guess(PuzzleImage choice) {
    if (_picked != null) return;
    setState(() => _picked = choice);

    if (_correct) {
      AudioService.instance.playClap();
    } else {
      AudioService.instance.playWrong();
    }

    // Çocuk doğru cevabı görsün diye kısa bir bekleme.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || _bildirildi) return;
      _bildirildi = true;
      widget.onGuessed(_correct);
    });
  }

  ({String title, String hint}) _copy(int revealed) {
    if (_picked != null) {
      return _correct
          ? (title: 'BİLDİN! 🎉', hint: 'Resim gerçekten ${_picked!.label}.')
          : (
              title: 'Bu değil 🙈',
              hint: 'Parçaların duruyor, yeni bir oyunla devam!',
            );
    }
    if (revealed == 0) {
      return (
        title: 'Bu hangi hayvan?',
        hint: 'Parça açmak için 80 puan gerekiyor — ama tahmin edebilirsin.',
      );
    }
    if (widget.newPiece != null) {
      return (title: 'Yeni parça açıldı!', hint: 'Sence bu hangi hayvan?');
    }
    if (revealed == PuzzleStore.pieceCount) {
      return (title: 'Resmin tamamı açık!', hint: 'Peki bu hangi hayvan?');
    }
    return (title: 'Bu hangi hayvan?', hint: 'Parça kazanmak için 80 puan.');
  }

  @override
  Widget build(BuildContext context) {
    final store = PuzzleStore.instance;

    return ValueListenableBuilder<int>(
      valueListenable: store.revealedMask,
      builder: (context, mask, _) {
        final revealed = store.revealedCount;
        final copy = _copy(revealed);

        return Column(
          children: [
            Text(
              copy.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.baloo2(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              copy.hint,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PuzzleBoard(
                    image: store.image,
                    revealedMask: mask,
                    newPiece: widget.newPiece,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _PieceCounter(revealed: revealed, total: PuzzleStore.pieceCount),
            const SizedBox(height: 10),
            _Choices(
              choices: _choices,
              picked: _picked,
              correctId: store.image.id,
              onPick: _guess,
            ),
          ],
        );
      },
    );
  }
}

/// "3 / 10 parça" göstergesi.
class _PieceCounter extends StatelessWidget {
  final int revealed;
  final int total;

  const _PieceCounter({required this.revealed, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.extension_rounded, color: AppColors.accent, size: 18),
          const SizedBox(width: 6),
          Text(
            '$revealed / $total parça',
            style: GoogleFonts.baloo2(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tahmin şıkları: 2×2 ızgara.
///
/// Tek sıra yerine ızgara, çünkü dar telefonlarda "KURBAĞA" gibi uzun adlar
/// dört yan yana düğmeye sığmıyordu.
class _Choices extends StatelessWidget {
  final List<PuzzleImage> choices;
  final PuzzleImage? picked;
  final String correctId;
  final ValueChanged<PuzzleImage> onPick;

  const _Choices({
    required this.choices,
    required this.picked,
    required this.correctId,
    required this.onPick,
  });

  /// Seçim yapılmadan önce hepsi mor; sonra doğru yeşil, seçilen yanlış kırmızı.
  Color _colorFor(PuzzleImage c) {
    if (picked == null) return AppColors.grape;
    if (c.id == correctId) return AppColors.success;
    if (c.id == picked!.id) return AppColors.danger;
    return AppColors.grape;
  }

  @override
  Widget build(BuildContext context) {
    final rows = <List<PuzzleImage>>[
      for (var i = 0; i < choices.length; i += 2)
        choices.sublist(i, min(i + 2, choices.length)),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows) ...[
          Row(
            children: [
              for (final c in row) ...[
                Expanded(
                  child: CandyButton(
                    label: c.label,
                    color: _colorFor(c),
                    height: 52,
                    fontSize: 19,
                    expand: false,
                    onPressed: picked == null ? () => onPick(c) : null,
                  ),
                ),
                if (c != row.last) const SizedBox(width: 10),
              ],
            ],
          ),
          if (row != rows.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
