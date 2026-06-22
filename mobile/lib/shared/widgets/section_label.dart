import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';

class SectionLabel extends StatelessWidget {
  final String title;
  const SectionLabel(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: NeoColors.ink,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(title,
          style: neoLabel(13, color: Colors.white).copyWith(letterSpacing: 1)),
    );
  }
}
