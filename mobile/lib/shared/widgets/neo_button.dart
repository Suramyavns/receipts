import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';

class NeoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color accent;
  final bool expand;

  const NeoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.accent = NeoColors.blue,
    this.expand = true,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          color: disabled ? NeoColors.surface : widget.accent,
          border: Border.all(color: NeoColors.ink, width: 2),
          borderRadius: BorderRadius.circular(4),
          boxShadow: _pressed || disabled
              ? []
              : [
                  const BoxShadow(
                    color: NeoColors.ink,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        transform: _pressed
            ? Matrix4.translationValues(4.0, 4.0, 0)
            : Matrix4.identity(),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: neoHeadline(15,
              color: disabled ? NeoColors.ink.withValues(alpha: 0.4) : NeoColors.ink),
        ),
      ),
    );
  }
}
