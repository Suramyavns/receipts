import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';

class TheReadCard extends StatelessWidget {
  final String text;
  const TheReadCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: neoBox(bg: NeoColors.yellow, offset: 5, radius: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THE READ', style: neoLabel(11).copyWith(letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(text,
              style: neoBody(14).copyWith(height: 1.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
