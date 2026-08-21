import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Ekranın üstüne konfeti yağmuru bindiren yardımcı widget.
///
/// [child] her zaman gösterilir; [controller] tetiklendiğinde üstte konfeti
/// patlar. Genellikle bir [Stack] içinde en üst katman olarak kullanılır.
class ConfettiOverlay extends StatelessWidget {
  final ConfettiController controller;

  const ConfettiOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirection: pi / 2, // aşağı doğru
        blastDirectionality: BlastDirectionality.explosive,
        emissionFrequency: 0.04,
        numberOfParticles: 20,
        maxBlastForce: 22,
        minBlastForce: 8,
        gravity: 0.25,
        shouldLoop: false,
        colors: const [
          Color(0xFFFF6B6B),
          Color(0xFFFFD93D),
          Color(0xFF6BCB77),
          Color(0xFF4D96FF),
          Color(0xFFFF6FB5),
          Color(0xFFB983FF),
        ],
      ),
    );
  }
}
