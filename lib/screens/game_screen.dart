import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/question.dart';
import '../services/audio_service.dart';
import '../services/avatar_store.dart';
import '../services/progress_store.dart';
import '../services/question_generator.dart';
import '../theme/app_colors.dart';
import '../widgets/candy_button.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/feedback_badge.dart';
import '../widgets/mascot.dart';
import '../widgets/slot_reel.dart';
import '../widgets/starry_background.dart';
import 'result_screen.dart';
import 'settings_screen.dart';

/// Soru çözme akışındaki aşamalar.
enum GamePhase { ready, spinning, answering }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const Duration _spinBase = Duration(milliseconds: 1500);

  // Oynanan kategori: oyun boyunca sabittir, sorular buna göre üretilir.
  late final int _category;

  late List<Question> _questions;
  final List<QuestionResult> _results = [];

  int _index = 0;
  String _input = '';
  GamePhase _phase = GamePhase.ready;

  // Yanlış cevap verildiğinde doğru cevabı kısa süre gösterip geçtiğimizde true.
  bool _revealedAnswer = false;

  // Cevap verildikten sonra (doğru/yanlış) sonraki soruya geçilene kadar true.
  // Bu sırada ÇEVİR kilitlidir: tik/geri bildirim görünürken tekrar çevirip
  // akışı bozmayı (ör. "?+?=?" ekranında takılmayı) önler.
  bool _resolving = false;

  // Canlı skor (her cevaptan sonra güncellenir, son değerlendirme buradan gelir).
  int get _correctSoFar => _results.where((r) => r.correct).length;
  int get _wrongSoFar => _results.length - _correctSoFar;

  // Çark kontrolcüleri.
  final SlotReelController _reelA = SlotReelController(initialValue: '?');
  final SlotReelController _reelOp = SlotReelController(initialValue: '?');
  final SlotReelController _reelB = SlotReelController(initialValue: '?');

  late final ConfettiController _confetti;
  final FeedbackBadgeController _badge = FeedbackBadgeController();

  // Geri bildirim efektleri (yumuşak overlay parlaması).
  bool _greenFlash = false;
  bool _redFlash = false;

  // Maskotun anlık ruh hali.
  MascotMood _mood = MascotMood.idle;

  static const List<String> _digitSymbols = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
  ];
  static const List<String> _opSymbols = ['+', '-', '×', '÷'];

  Question get _current => _questions[_index];

  @override
  void initState() {
    super.initState();
    _category = ProgressStore.instance.category.value;
    _questions = QuestionGenerator(category: _category).generateAll();
    _confetti =
        ConfettiController(duration: const Duration(milliseconds: 1200));
  }

  @override
  void dispose() {
    _reelA.dispose();
    _reelOp.dispose();
    _reelB.dispose();
    _confetti.dispose();
    _badge.dispose();
    super.dispose();
  }

  // ---- Oyun akışı --------------------------------------------------------

  void _spin() {
    if (_phase != GamePhase.ready || _resolving) return;
    setState(() {
      _phase = GamePhase.spinning;
      _input = '';
      _revealedAnswer = false;
      _mood = MascotMood.thinking;
    });

    final q = _current;
    // Sağ çark: ikinci operand bilinmiyorsa '?' üzerinde durur.
    final bDisplay =
        q.missing == MissingSlot.operandB ? '?' : q.b.toString();

    _reelA.spinTo(q.a.toString(), duration: _spinBase);
    _reelOp.spinTo(q.op.symbol, duration: _spinBase);
    _reelB.spinTo(bDisplay, duration: _spinBase);

    // En geç duran çark (200ms gecikmeli) bitince cevap aşamasına geç.
    final total = _spinBase + const Duration(milliseconds: 250);
    Future.delayed(total, () {
      if (!mounted) return;
      setState(() => _phase = GamePhase.answering);
    });
  }

  void _onKeyTap(String digit) {
    if (_phase != GamePhase.answering) return;
    if (_input.length >= 6) return; // makul üst sınır (4 basamaklı bantta yeterli)
    setState(() => _input += digit);
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _onClear() {
    if (_input.isEmpty) return;
    setState(() => _input = '');
  }

  void _submit() {
    if (_phase != GamePhase.answering) return;
    if (_input.isEmpty) return;

    final given = int.tryParse(_input);
    if (given == null) return;

    if (given == _current.correctAnswer) {
      _handleCorrect(given);
    } else {
      _handleWrong(given);
    }
  }

  void _handleCorrect(int given) {
    AudioService.instance.playClap();
    _confetti.play();
    _badge.show(correct: true);
    setState(() {
      _greenFlash = true;
      _mood = MascotMood.happy;
      _phase = GamePhase.ready;
      _resolving = true; // ÇEVİR'i kilitle: tik görünürken tekrar çevirme
    });
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _greenFlash = false);
    });

    _recordResult(correct: true, given: given);

    // 1 saniye sonra sonraki soru.
    Future.delayed(const Duration(seconds: 1), _goNext);
  }

  void _handleWrong(int given) {
    HapticFeedback.heavyImpact();
    AudioService.instance.playWrong();
    _badge.show(correct: false);
    // Yanlış da olsa soruyu bitiriyoruz: doğru cevabı kısa süre gösterip geç.
    setState(() {
      _redFlash = true;
      _revealedAnswer = true;
      _mood = MascotMood.sad;
      _phase = GamePhase.ready;
      _resolving = true; // ÇEVİR'i kilitle: geri bildirim görünürken çevirme
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _redFlash = false);
    });

    _recordResult(correct: false, given: given);

    // Doğru cevabı görsün diye biraz daha bekleyip sonraki soruya geç.
    Future.delayed(const Duration(milliseconds: 1600), _goNext);
  }

  void _recordResult({required bool correct, required int? given}) {
    _results.add(QuestionResult(
      question: _current,
      correct: correct,
      givenAnswer: given,
    ));
  }

  void _goNext() {
    if (!mounted) return;
    if (_index + 1 >= _questions.length) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            category: _category,
            results: List.of(_results),
          ),
        ),
      );
      return;
    }
    setState(() {
      _index += 1;
      _phase = GamePhase.ready;
      _resolving = false; // kilidi kaldır: yeni soru çevrilmeye hazır
      _input = '';
      _revealedAnswer = false;
      _mood = MascotMood.idle;
      _reelA.setValue('?');
      _reelOp.setValue('?');
      _reelB.setValue('?');
    });
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  // ---- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final progress = (_index + 1) / _questions.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StarryBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildProgress(progress),
                    const SizedBox(height: 8),
                    // Kaydırma yok: içerik her cihazda ekrana sığar. Üst bölge
                    // (maskot + çarklar) gerekirse küçülür; cevap alanı (klavye
                    // + TAMAM) her zaman görünür kalır.
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxW = constraints.maxWidth;
                          final top = SizedBox(
                            width: maxW,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ValueListenableBuilder<int>(
                                  valueListenable:
                                      AvatarStore.instance.selectedIndex,
                                  builder: (context, idx, _) => Mascot(
                                    mood: _mood,
                                    skin: mascotSkins[idx],
                                    size: 88,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildReels(),
                              ],
                            ),
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Üst bölge tüm artan alanı alır, sığmazsa küçülür.
                              Expanded(
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: top,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Cevap alanı: yüksekliği sınırlı; gerekirse oransal
                              // küçülür ama asla ekrandan taşmaz.
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: constraints.maxHeight * 0.74,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.bottomCenter,
                                  child: SizedBox(
                                    width: maxW,
                                    child: _buildAnswerArea(),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Yumuşak yeşil / kırmızı parlama (radyal, kenarlardan).
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _greenFlash ? 1 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: const _EdgeGlow(color: AppColors.success),
              ),
            ),
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _redFlash ? 1 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const _EdgeGlow(color: AppColors.danger),
              ),
            ),

            // Ortada zıplayan ✓ / ✗ rozeti.
            FeedbackBadge(controller: _badge),

            // Konfeti her zaman en üstte.
            ConfettiOverlay(controller: _confetti),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: _CategoryChip(category: _category)),
            const SizedBox(width: 8),
            // Doğru/yanlış sayaçları + hemen sağında ayarlar dişlisi.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LiveScore(correct: _correctSoFar, wrong: _wrongSoFar),
                const SizedBox(width: 8),
                _GearButton(onTap: _openSettings),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Soru ${_index + 1} / ${_questions.length}',
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.baloo2(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 14,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReels() {
    final q = _current;
    // "=" sağındaki hücre: sonuç bilinmiyorsa '?', biliniyorsa sonuç.
    final resultKnown = q.missing == MissingSlot.operandB;
    final resultText =
        (_phase == GamePhase.ready && !_revealedAnswer)
            ? '?'
            : (resultKnown ? q.result.toString() : '?');
    final highlightResult = q.missing == MissingSlot.result;

    final equals = Text(
      '=',
      style: GoogleFonts.baloo2(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );

    // Slot makinesi gövdesi (housing): çarkları ve sonucu tek bir makinede
    // toplar. Dar ekranlarda taşmamak için iç satır FittedBox ile küçülür.
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C2160), Color(0xFF1A1340)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.9), width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.grape.withValues(alpha: 0.45),
            blurRadius: 24,
            spreadRadius: 1,
          ),
          const BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          // Üstte yanıp sönen makine ışıkları.
          const _MarqueeLights(),
          const SizedBox(height: 12),
          // İç pencere (koyu inset) + çarklar.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SlotReel(
                    controller: _reelA,
                    symbols: _digitSymbols,
                    backgroundColor: AppColors.reelA,
                    stopDelay: Duration.zero,
                  ),
                  const SizedBox(width: 6),
                  SlotReel(
                    controller: _reelOp,
                    symbols: _opSymbols,
                    backgroundColor: AppColors.reelOp,
                    width: 76,
                    stopDelay: const Duration(milliseconds: 120),
                  ),
                  const SizedBox(width: 6),
                  SlotReel(
                    controller: _reelB,
                    symbols: _digitSymbols,
                    backgroundColor: AppColors.reelB,
                    stopDelay: const Duration(milliseconds: 250),
                  ),
                  const SizedBox(width: 10),
                  equals,
                  const SizedBox(width: 10),
                  _ResultCell(text: resultText, highlight: highlightResult),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerArea() {
    switch (_phase) {
      case GamePhase.ready:
        if (_revealedAnswer) {
          return _RevealCard(question: _current);
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: CandyButton(
            label: 'ÇEVİR',
            icon: Icons.casino_rounded,
            color: AppColors.accent,
            foreground: AppColors.ink,
            height: 72,
            fontSize: 30,
            // Cevap çözülürken (tik/geri bildirim ekranı) kilitli.
            onPressed: _resolving ? null : _spin,
          ),
        );
      case GamePhase.spinning:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Çevriliyor...',
            style: GoogleFonts.baloo2(
              fontSize: 24,
              color: Colors.white70,
            ),
          ),
        );
      case GamePhase.answering:
        return _AnswerPad(
          input: _input,
          onKey: _onKeyTap,
          onBackspace: _onBackspace,
          onClear: _onClear,
          onSubmit: _submit,
        );
    }
  }
}

// ---- Alt widget'lar ------------------------------------------------------

/// Ekranın üstünde oyuncunun bulunduğu kategoriyi gösteren rozet.
class _CategoryChip extends StatelessWidget {
  final int category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.grape, Color(0xFF7B2FBE)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.9),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.grape.withValues(alpha: 0.5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: AppColors.sunny, size: 22),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Kategori $category',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.baloo2(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Başlıkta canlı doğru/yanlış sayacı.
class _LiveScore extends StatelessWidget {
  final int correct;
  final int wrong;

  const _LiveScore({required this.correct, required this.wrong});

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, int value, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: GoogleFonts.baloo2(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        chip(Icons.check_circle_rounded, correct, AppColors.success),
        const SizedBox(width: 8),
        chip(Icons.cancel_rounded, wrong, AppColors.danger),
      ],
    );
  }
}

/// Üst şeritteki kompakt ayarlar (dişli) butonu.
class _GearButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38, width: 1.5),
        ),
        child: const Icon(Icons.settings_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

/// Slot makinesi gövdesinin üstündeki yanıp sönen ışık şeridi.
class _MarqueeLights extends StatefulWidget {
  const _MarqueeLights();

  @override
  State<_MarqueeLights> createState() => _MarqueeLightsState();
}

class _MarqueeLightsState extends State<_MarqueeLights>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  static const _colors = [
    AppColors.coral,
    AppColors.sunny,
    AppColors.mint,
    AppColors.sky,
    AppColors.grape,
  ];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const count = 9;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final active = (_c.value * count).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (i) {
            final on = i == active;
            final color = _colors[i % _colors.length];
            return Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? color : color.withValues(alpha: 0.25),
                boxShadow: on
                    ? [BoxShadow(color: color, blurRadius: 8, spreadRadius: 1)]
                    : null,
              ),
            );
          }),
        );
      },
    );
  }
}

/// Kenarlardan içe doğru yumuşayan radyal parlama (sert tam ekran flaş yerine).
class _EdgeGlow extends StatelessWidget {
  final Color color;

  const _EdgeGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.1,
          colors: [
            color.withValues(alpha: 0.0),
            color.withValues(alpha: 0.10),
            color.withValues(alpha: 0.45),
          ],
          stops: const [0.55, 0.8, 1.0],
        ),
      ),
    );
  }
}

class _ResultCell extends StatelessWidget {
  final String text;
  final bool highlight;

  const _ResultCell({required this.text, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 114,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.accent.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight ? AppColors.accent : Colors.white38,
          width: highlight ? 4 : 2,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      // Değer değişince "pop" ile belirsin.
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: child,
        ),
        // Çok basamaklı sonuçlar kutuya sığmayıp satır sarmasın diye tek
        // satıra zorlanır ve gerekirse küçültülür.
        child: Padding(
          key: ValueKey(text),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              style: GoogleFonts.baloo2(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RevealCard extends StatelessWidget {
  final Question question;

  const _RevealCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: Column(
        children: [
          const Text('🙈', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            'Doğru cevap:',
            style: GoogleFonts.nunito(
              fontSize: 20,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          // Dört basamaklı sayılarla uzayan işlem satırı taşmasın.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              question.solvedPrompt,
              maxLines: 1,
              softWrap: false,
              style: GoogleFonts.baloo2(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cevap kutusu + sayı klavyesi + TAMAM butonu.
class _AnswerPad extends StatelessWidget {
  final String input;
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  const _AnswerPad({
    required this.input,
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cevap görüntüleme kutusu.
        Container(
          width: double.infinity,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            input.isEmpty ? 'Cevabın' : input,
            style: GoogleFonts.baloo2(
              fontSize: input.isEmpty ? 26 : 40,
              fontWeight: FontWeight.w700,
              color: input.isEmpty
                  ? Colors.black38
                  : const Color(0xFF3A1C71),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _Keypad(onKey: onKey, onBackspace: onBackspace, onClear: onClear),
        const SizedBox(height: 10),
        CandyButton(
          label: 'TAMAM',
          icon: Icons.check_rounded,
          color: AppColors.success,
          height: 58,
          fontSize: 26,
          onPressed: input.isEmpty ? null : onSubmit,
        ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  const _Keypad({
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    Widget keyButton(String label, {VoidCallback? onTap, Color? color}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: CandyButton(
            label: label,
            color: color ?? AppColors.grape,
            height: 50,
            fontSize: 25,
            onPressed: onTap ?? () => onKey(label),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [keyButton('1'), keyButton('2'), keyButton('3')]),
        Row(children: [keyButton('4'), keyButton('5'), keyButton('6')]),
        Row(children: [keyButton('7'), keyButton('8'), keyButton('9')]),
        Row(
          children: [
            keyButton('C', onTap: onClear, color: AppColors.danger),
            keyButton('0'),
            keyButton('⌫', onTap: onBackspace, color: AppColors.sky),
          ],
        ),
      ],
    );
  }
}
