import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'chunky_button.dart';

/// Bir söz paylaşıldığında çıkan kutlama ekranı.
///
/// Amaç şu: paylaş butonuna basıp küçük bir gri bildirim görmek hiçbir şey
/// hissettirmiyor. Bir an duraklayıp "bunu sen yaptın" demek, insanın
/// tekrar paylaşmak istemesini sağlayan şey.
class CelebrationSheet {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String buttonLabel,
    IconData icon = Icons.auto_awesome,
  }) async {
    HapticFeedback.heavyImpact();
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CelebrationBody(
        title: title,
        subtitle: subtitle,
        buttonLabel: buttonLabel,
        icon: icon,
      ),
    );
  }
}

class _CelebrationBody extends StatefulWidget {
  const _CelebrationBody({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;

  @override
  State<_CelebrationBody> createState() => _CelebrationBodyState();
}

class _CelebrationBodyState extends State<_CelebrationBody>
    with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  @override
  void dispose() {
    _pop.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: CurvedAnimation(
                      parent: _pop, curve: Curves.elasticOut),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.14),
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: Icon(widget.icon, color: AppColors.gold, size: 40),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                ChunkyButton(
                  label: widget.buttonLabel,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
        // Konfeti — altın tonlarda, kısa ve abartısız.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _confetti,
              builder: (context, _) => CustomPaint(
                painter: _ConfettiPainter(_confetti.value),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);
  final double t;

  // Sabit tohum: her açılışta aynı desen, titreme yok.
  static final _rnd = math.Random(7);
  static final _seeds = List.generate(
    26,
    (_) => (
      x: _rnd.nextDouble(),
      delay: _rnd.nextDouble() * 0.3,
      drift: _rnd.nextDouble() * 2 - 1,
      spin: _rnd.nextDouble() * 6,
      size: 4.0 + _rnd.nextDouble() * 5,
      gold: _rnd.nextBool(),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _seeds) {
      final p = ((t - s.delay) / (1 - s.delay)).clamp(0.0, 1.0);
      if (p <= 0) continue;

      final y = size.height * 0.75 * p - 20;
      final x = size.width * s.x + s.drift * 40 * p;
      final fade = p < 0.7 ? 1.0 : (1 - (p - 0.7) / 0.3);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(s.spin + p * 6);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: s.size, height: s.size * 1.6),
        Paint()
          ..color = (s.gold ? AppColors.gold : AppColors.goldSoft)
              .withValues(alpha: fade * 0.9),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Beğeni anında yukarı süzülen "+1" — küçük ama bağımlılık yapan geri bildirim.
class FloatingPlusOne extends StatelessWidget {
  const FloatingPlusOne({super.key, required this.animation, this.label = '+1'});

  final Animation<double> animation;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final v = animation.value;
        if (v == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: v < 0.75 ? 1.0 : (1 - (v - 0.75) / 0.25),
          child: Transform.translate(
            offset: Offset(0, -46 * v),
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
    );
  }
}
