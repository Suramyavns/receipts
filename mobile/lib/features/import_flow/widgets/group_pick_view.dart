import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/widgets/primary_button.dart';

class GroupPickView extends StatelessWidget {
  final List<String> participants;
  final String? pickedA, pickedB;
  final ValueChanged<String> onPickedA, onPickedB;
  final VoidCallback onConfirm, onCancel;

  const GroupPickView({
    super.key,
    required this.participants,
    required this.pickedA,
    required this.pickedB,
    required this.onPickedA,
    required this.onPickedB,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final canConfirm = pickedA != null && pickedB != null && pickedA != pickedB;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GROUP CHAT', style: neoDisplay(17)),
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: NeoColors.surface,
                    border: Border.all(color: NeoColors.ink, width: 2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text('CANCEL', style: neoLabel(11)),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: NeoColors.ink, thickness: 3, height: 3),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pick two people to compare head-to-head.',
                    style: neoBody(15, color: NeoColors.ink.withValues(alpha: 0.6))),
                const SizedBox(height: 24),
                Text('PERSON A', style: neoLabel(12).copyWith(letterSpacing: 1)),
                const SizedBox(height: 10),
                PersonPicker(
                    participants: participants,
                    selected: pickedA,
                    exclude: pickedB,
                    accent: NeoColors.blue,
                    onSelected: onPickedA),
                const SizedBox(height: 20),
                Text('PERSON B', style: neoLabel(12).copyWith(letterSpacing: 1)),
                const SizedBox(height: 10),
                PersonPicker(
                    participants: participants,
                    selected: pickedB,
                    exclude: pickedA,
                    accent: NeoColors.pink,
                    onSelected: onPickedB),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: canConfirm
                      ? 'COMPARE $pickedA VS $pickedB'
                      : 'PICK TWO DIFFERENT PEOPLE',
                  onTap: canConfirm ? onConfirm : null,
                  bg: NeoColors.blue,
                  textColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PersonPicker extends StatelessWidget {
  final List<String> participants;
  final String? selected, exclude;
  final Color accent;
  final ValueChanged<String> onSelected;

  const PersonPicker({
    super.key,
    required this.participants,
    required this.selected,
    required this.exclude,
    required this.accent,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: participants.where((p) => p != exclude).map((p) {
        final isSel = p == selected;
        return GestureDetector(
          onTap: () => onSelected(p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? accent : NeoColors.surface,
              border: Border.all(color: NeoColors.ink, width: 2),
              borderRadius: BorderRadius.circular(4),
              boxShadow: isSel
                  ? const [BoxShadow(color: NeoColors.ink, offset: Offset(3, 3), blurRadius: 0)]
                  : [],
            ),
            child: Text(p,
                style: neoBody(14, color: isSel ? Colors.white : NeoColors.ink)),
          ),
        );
      }).toList(),
    );
  }
}
