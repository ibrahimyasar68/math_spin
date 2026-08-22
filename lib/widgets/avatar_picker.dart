import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/avatar_store.dart';
import 'mascot.dart';

/// Avatarı değiştirmek için yatay seçim satırı.
class AvatarPicker extends StatelessWidget {
  /// Üstte "Avatarını seç" başlığı gösterilsin mi? (Ayarlar kartında kapalı.)
  final bool showTitle;

  const AvatarPicker({super.key, this.showTitle = true});

  @override
  Widget build(BuildContext context) {
    final store = AvatarStore.instance;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle) ...[
          Text(
            'Avatarını seç',
            style: GoogleFonts.baloo2(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
        ],
        ValueListenableBuilder<int>(
          valueListenable: store.selectedIndex,
          // Wrap: avatar sayısı arttığında dar ekranda taşmak yerine alt
          // satıra iner; dokunma hedefleri küçülmez.
          builder: (context, selected, _) => Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < mascotSkins.length; i++)
                _AvatarChip(
                  skin: mascotSkins[i],
                  selected: i == selected,
                  onTap: () => store.select(i),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarChip extends StatelessWidget {
  final MascotSkin skin;
  final bool selected;
  final VoidCallback onTap;

  const _AvatarChip({
    required this.skin,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: selected ? 0.18 : 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: selected ? 3 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: skin.headTop.withValues(alpha: 0.7),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: CustomPaint(
            size: const Size(34, 34),
            painter: _MiniMascotPainter(skin: skin),
          ),
        ),
      ),
    );
  }
}

/// Seçici için hafif, animasyonsuz mini maskot kafası.
class _MiniMascotPainter extends CustomPainter {
  final MascotSkin skin;

  _MiniMascotPainter({required this.skin});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Anten.
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.08),
      w * 0.07,
      Paint()..color = skin.antenna,
    );

    // Kulaklar.
    final earPaint = Paint()..color = skin.ear;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.02, h * 0.42, w * 0.1, h * 0.24),
        Radius.circular(w * 0.05),
      ),
      earPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.88, h * 0.42, w * 0.1, h * 0.24),
        Radius.circular(w * 0.05),
      ),
      earPaint,
    );

    // Kafa.
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.2, w * 0.72, h * 0.7),
      Radius.circular(w * 0.26),
    );
    canvas.drawRRect(
      headRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skin.headTop, skin.headBottom],
        ).createShader(headRect.outerRect),
    );

    // Yüz paneli + gözler.
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.26, h * 0.36, w * 0.48, h * 0.34),
      Radius.circular(w * 0.14),
    );
    canvas.drawRRect(faceRect, Paint()..color = const Color(0xFF14102E));
    final eye = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.4, h * 0.52), w * 0.06, eye);
    canvas.drawCircle(Offset(w * 0.6, h * 0.52), w * 0.06, eye);
  }

  @override
  bool shouldRepaint(covariant _MiniMascotPainter oldDelegate) =>
      oldDelegate.skin.name != skin.name;
}
