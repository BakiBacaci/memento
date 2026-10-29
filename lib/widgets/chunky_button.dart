import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Duolingo tipi "basılabilir" buton.
///
/// Numara basit ama etkili: butonun altında koyu bir kenar var, basınca o
/// kenar kayboluyor ve buton aşağı iniyor. Fiziksel bir tuşa basmış gibi
/// hissettiriyor. Düz Material butonlarında bu his hiç yok.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.gold,
    this.foreground = Colors.black,
    this.loading = false,
    this.expand = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color foreground;
  final bool loading;
  final bool expand;
  final bool compact;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  static const _depth = 4.0;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final base = enabled ? widget.color : AppColors.border;
    final shadow = Color.lerp(base, Colors.black, 0.45)!;
    final height = widget.compact ? 42.0 : 54.0;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed!.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.expand ? double.infinity : null,
        height: height + _depth,
        padding: EdgeInsets.only(
          top: _down ? _depth : 0,
          bottom: _down ? 0 : _depth,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _down
                ? null
                : [BoxShadow(color: shadow, offset: const Offset(0, _depth))],
          ),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 18 : 24),
          child: widget.loading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: widget.foreground, strokeWidth: 2.4),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.foreground, size: 19),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.foreground,
                          fontWeight: FontWeight.w800,
                          fontSize: widget.compact ? 13 : 15,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// İkincil buton — dolu değil, çerçeveli. Aynı basma hissi.
class ChunkyOutlineButton extends StatelessWidget {
  const ChunkyOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool compact;
  final bool expand;

  @override
  Widget build(BuildContext context) => ChunkyButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        compact: compact,
        expand: expand,
        color: AppColors.surface2,
        foreground: Colors.white,
      );
}
