import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';

class NavButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  const NavButton({super.key, this.icon = '←', required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: neoBox(bg: NeoColors.surface, offset: 3, radius: 6, borderWidth: 3),
        alignment: Alignment.center,
        child: Text(icon, style: neoHeadline(16)),
      ),
    );
  }
}
