import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Çocuk dostu, kalın gövdeli, basılınca aşağı inen 3B (tactile) buton.
///
/// Altında sabit koyu bir "gövde" katmanı vardır; basıldığında yüz katmanı
/// [depth] kadar aşağı kayar ve gövdeyi örterek gerçekten basılmış hissi verir.
class CandyButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;

  /// Üst yüz metni/ikon rengi.
  final Color foreground;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final bool expand;

  const CandyButton({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.foreground = Colors.white,
    this.onPressed,
    this.height = 64,
    this.fontSize = 24,
    this.expand = true,
  });

  @override
  State<CandyButton> createState() => _CandyButtonState();
}

class _CandyButtonState extends State<CandyButton> {
  static const double _depth = 7;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool v) {
    if (!_enabled) return;
    if (_pressed != v) setState(() => _pressed = v);
  }

  Color _darken(Color c, [double amount = 0.28]) =>
      Color.lerp(c, Colors.black, amount)!;

  Color _lighten(Color c, [double amount = 0.18]) =>
      Color.lerp(c, Colors.white, amount)!;

  @override
  Widget build(BuildContext context) {
    final baseColor = _enabled ? widget.color : const Color(0xFF5A5570);
    final faceColor = _enabled ? widget.color : const Color(0xFF6E6886);
    final sideColor = _darken(baseColor);
    final offsetY = _pressed ? _depth : 0.0;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon,
              size: widget.fontSize + 6,
              color: _enabled ? widget.foreground : Colors.white60),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.baloo2(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w700,
              color: _enabled ? widget.foreground : Colors.white60,
            ),
          ),
        ),
      ],
    );

    final button = GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _enabled ? widget.onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: widget.height + _depth,
        child: Stack(
          children: [
            // Sabit alt gövde (yan yüzey) — 3B derinlik hissi.
            Positioned(
              left: 0,
              right: 0,
              top: _depth,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: sideColor,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            // Üst yüz — basılınca aşağı kayar.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: offsetY,
              height: widget.height,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_lighten(faceColor), faceColor],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );

    return widget.expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
