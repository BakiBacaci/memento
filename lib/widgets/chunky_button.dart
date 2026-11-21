import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Ana düğme: siyah hap, basınca hafifçe küçülür.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.foreground,
    this.loading = false,
    this.expand = true,
    this.compact = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color? foreground;
  final bool loading;
  final bool expand;
  final bool compact;
  final bool outlined;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final color = widget.color ?? AppColors.textPrimary;
    final foreground = widget.foreground ?? AppColors.bg;
    final bg = widget.outlined
        ? Colors.transparent
        : (enabled ? color : AppColors.border);
    final fg = widget.outlined ? color : foreground;
    final height = widget.compact ? 46.0 : 56.0;

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
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: widget.expand ? double.infinity : null,
          height: height,
          decoration: ShapeDecoration(
            color: bg,
            shape: StadiumBorder(
              side: widget.outlined
                  ? BorderSide(color: color, width: 2)
                  : BorderSide.none,
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: widget.loading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: fg, strokeWidth: 2.4),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: fg, size: 19),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w600,
                          fontSize: widget.compact ? 15 : 16,
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

/// İkincil düğme: çerçeveli hap.
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
        outlined: true,
      );
}
