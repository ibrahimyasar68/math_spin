import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Doğru/yanlış geri bildirim rozetini dışarıdan tetiklemek için kullanılır.
class FeedbackBadgeController extends ChangeNotifier {
  bool _correct = true;
  int _token = 0;

  bool get correct => _correct;
  int get token => _token;

  /// Ortada büyük bir ✓ ya da ✗ rozetini zıplatarak gösterir.
  void show({required bool correct}) {
    _correct = correct;
    _token++;
    notifyListeners();
  }
}

/// Ekranın ortasında belirip zıplayan (elasticOut) ve sönen geri bildirim rozeti.
class FeedbackBadge extends StatefulWidget {
  final FeedbackBadgeController controller;

  const FeedbackBadge({super.key, required this.controller});

  @override
  State<FeedbackBadge> createState() => _FeedbackBadgeState();
}

class _FeedbackBadgeState extends State<FeedbackBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  int _lastToken = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    widget.controller.addListener(_onTrigger);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTrigger);
    _anim.dispose();
    super.dispose();
  }

  void _onTrigger() {
    if (widget.controller.token == _lastToken) return;
    _lastToken = widget.controller.token;
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            final t = _anim.value;
            if (t == 0 || t >= 1) return const SizedBox.shrink();

            // İlk %55: elasticOut ile büyüyerek gir. Son %25: küçülüp sön.
            final inProgress = (t / 0.55).clamp(0.0, 1.0);
            final scaleIn = Curves.elasticOut.transform(inProgress);
            const outStart = 0.75;
            final outProgress =
                ((t - outStart) / (1 - outStart)).clamp(0.0, 1.0);
            final opacity = (1 - outProgress).clamp(0.0, 1.0);
            final scale = scaleIn * (1 - 0.15 * outProgress);

            final correct = widget.controller.correct;
            final color = correct ? AppColors.success : AppColors.danger;

            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    correct ? Icons.check_rounded : Icons.close_rounded,
                    size: 90,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
