import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tek bir slot makinesi çarkını dışarıdan kontrol etmek için kullanılır.
///
/// Çark, [SlotReel] içinde bir [GlobalKey] yerine controller deseni ile
/// yönetilir; böylece [GameScreen] tüm çarkları aynı anda tetikleyip her
/// birine farklı durma gecikmesi verebilir.
class SlotReelController extends ChangeNotifier {
  String _value;
  bool _spinning = false;

  // Spin tetikleyici; her artışta SlotReel yeni bir animasyon başlatır.
  int _spinToken = 0;
  Duration _spinDuration = const Duration(milliseconds: 1500);

  SlotReelController({String initialValue = '?'}) : _value = initialValue;

  String get value => _value;
  bool get spinning => _spinning;
  int get spinToken => _spinToken;
  Duration get spinDuration => _spinDuration;

  /// Çarkı döndürür ve animasyon bitince [finalValue] üzerinde durur.
  void spinTo(String finalValue, {Duration? duration}) {
    _value = finalValue;
    if (duration != null) _spinDuration = duration;
    _spinning = true;
    _spinToken++;
    notifyListeners();
  }

  /// Animasyonsuz olarak değeri ayarlar (ör. ilk açılış / sıfırlama).
  void setValue(String finalValue) {
    _value = finalValue;
    _spinning = false;
    _spinToken++;
    notifyListeners();
  }

  // SlotReel, animasyon tamamlandığında bunu çağırır.
  void _markStopped() {
    _spinning = false;
    notifyListeners();
  }
}

/// Slot makinesi görünümünde, dikey eksende kayan tek bir çark.
class SlotReel extends StatefulWidget {
  final SlotReelController controller;

  /// Çarkın bu örneğe özel durma gecikmesi (çarklar sırayla dursun diye).
  final Duration stopDelay;

  /// Çark üzerinde gösterilebilecek olası semboller (filler için kullanılır).
  final List<String> symbols;

  final Color backgroundColor;
  final double width;
  final double height;

  const SlotReel({
    super.key,
    required this.controller,
    required this.symbols,
    this.stopDelay = Duration.zero,
    this.backgroundColor = const Color(0xFF6C63FF),
    this.width = 96,
    this.height = 120,
  });

  @override
  State<SlotReel> createState() => _SlotReelState();
}

class _SlotReelState extends State<SlotReel> with TickerProviderStateMixin {
  late final AnimationController _animController;
  // Çark durduğunda kısa bir "zıplama" (squash & stretch) efekti.
  late final AnimationController _bounce;
  final Random _rng = Random();

  /// Animasyon boyunca kayan öğeler; sonuncusu her zaman gerçek değerdir.
  List<String> _items = const ['?'];
  int _lastToken = -1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this);
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1,
    );
    _items = [widget.controller.value];
    _lastToken = widget.controller.spinToken;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _animController.dispose();
    _bounce.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final c = widget.controller;
    if (c.spinToken == _lastToken) return;
    _lastToken = c.spinToken;

    if (c.spinning) {
      _startSpin(c.value, c.spinDuration);
    } else {
      // Animasyonsuz set: doğrudan değeri göster.
      setState(() => _items = [c.value]);
      _animController.value = 1.0;
    }
  }

  Future<void> _startSpin(String finalValue, Duration baseDuration) async {
    // Bu çarka özel gecikme: önce kısa bir bekleme yapmak yerine toplam
    // süreyi uzatarak sıralı durma hissi veriyoruz.
    final total = baseDuration + widget.stopDelay;

    // Kayacak öğe listesi: bir sürü rastgele filler + en sonda gerçek değer.
    const fillerCount = 18;
    final items = <String>[];
    for (var i = 0; i < fillerCount; i++) {
      items.add(widget.symbols[_rng.nextInt(widget.symbols.length)]);
    }
    items.add(finalValue);

    setState(() => _items = items);

    _animController
      ..duration = total
      ..reset();

    try {
      // easeOut: hızlı başlar, sona doğru yavaşlayıp gerçek değerde durur.
      await _animController.animateTo(1.0, curve: Curves.easeOutCubic);
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    // Durunca kısa bir zıplama.
    _bounce.forward(from: 0);
    widget.controller._markStopped();
  }

  // Kenarlık kalınlığı; iç (görünür) yükseklik hesabında düşülür.
  static const double _borderWidth = 3;

  @override
  Widget build(BuildContext context) {
    // Kenarlık, içerik alanından üst+alt toplam 2*_borderWidth kadar yer kapar.
    // Hücre yüksekliğini buna göre küçültmezsek RenderFlex taşması oluşur.
    final innerHeight = widget.height - 2 * _borderWidth;

    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        // Tek seferlik squash & stretch: ortada zirve yapan bir darbe.
        final pulse = sin(_bounce.value * pi);
        final sy = 1 + 0.16 * pulse;
        final sx = 1 - 0.10 * pulse;
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.diagonal3Values(sx, sy, 1),
          child: child,
        );
      },
      child: Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.backgroundColor,
            Color.lerp(widget.backgroundColor, Colors.black, 0.25)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: _borderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Kayan içerik. OverflowBox, dikey eksende sınırsız yükseklik tanıyarak
          // çok sayıda hücre yığıldığında RenderFlex taşma uyarısını engeller;
          // Container'ın clipBehavior'ı taşan kısmı zaten kırpar.
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              final itemHeight = innerHeight;
              final maxOffset = (_items.length - 1) * itemHeight;
              final dy = -_animController.value * maxOffset;
              return OverflowBox(
                minHeight: 0,
                maxHeight: double.infinity,
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _items
                        .map((s) => _ReelCell(text: s, height: itemHeight))
                        .toList(),
                  ),
                ),
              );
            },
          ),
          // Üst/alt karartma ile slot penceresi hissi.
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  stops: const [0.0, 0.25, 0.75, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _ReelCell extends StatelessWidget {
  final String text;
  final double height;

  const _ReelCell({required this.text, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      // Çok basamaklı sayılar (ör. 4 basamaklı) hücreye sığmayıp satır
      // sarmasın diye tek satıra zorlanır ve gerekirse küçültülür.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              style: GoogleFonts.fredoka(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: const [
                  Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
