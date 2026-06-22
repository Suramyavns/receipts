import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color bg;
  final double offset;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  const NeoCard({
    super.key,
    required this.child,
    this.bg = NeoColors.cardBg,
    this.offset = 4,
    this.padding = const EdgeInsets.all(16),
    this.radius = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      decoration: neoBox(bg: bg, offset: offset, radius: radius),
      padding: padding,
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(
      onTap: onTap,
      child: box,
    );
  }
}
