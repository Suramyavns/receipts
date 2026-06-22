import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/tokens.dart';
import '../../domain/models/analysis_run.dart';


class NeoTimelineNode extends StatefulWidget {
  final AnalysisRun run;
  final bool isFirst;
  final bool isLast;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NeoTimelineNode({
    super.key,
    required this.run,
    this.isFirst = false,
    this.isLast = false,
    this.isSelected = false,
    this.accentColor = NeoColors.blue,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<NeoTimelineNode> createState() => _NeoTimelineNodeState();
}

class _NeoTimelineNodeState extends State<NeoTimelineNode> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final accent = widget.accentColor;
    final dateStr = DateFormat('MMM d').format(run.importedAt).toUpperCase();
    final hasTag = run.headline != null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Connector column ───────────────────────────────────────────────
          SizedBox(
            width: 20,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Vertical line
                Positioned(
                  top: widget.isFirst ? 36 : 0,
                  bottom: widget.isLast ? 36 : 0,
                  left: 8,
                  child: Container(
                    width: 4,
                    color: NeoColors.ink,
                  ),
                ),
                // Diamond dot
                Positioned(
                  top: 26,
                  left: 2,
                  child: Transform.rotate(
                    angle: 0.785398,
                    child: Container(
                      width: 15,
                      height: 15,
                      color: accent,
                      foregroundDecoration: BoxDecoration(
                        border: Border.all(color: NeoColors.ink, width: 3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // ── Card ──────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _pressed = true),
                onTapUp: (_) {
                  setState(() => _pressed = false);
                  widget.onTap();
                },
                onTapCancel: () => setState(() => _pressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  transform: _pressed
                      ? Matrix4.translationValues(3, 3, 0)
                      : Matrix4.identity(),
                  decoration: BoxDecoration(
                    color: NeoColors.surface,
                    border: Border.all(color: NeoColors.ink, width: 3),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: _pressed
                        ? const [
                            BoxShadow(
                                color: NeoColors.ink,
                                offset: Offset(2, 2),
                                blurRadius: 0)
                          ]
                        : const [
                            BoxShadow(
                                color: NeoColors.ink,
                                offset: Offset(5, 5),
                                blurRadius: 0)
                          ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + date + delete
                      Row(
                        children: [
                          Expanded(
                            child: Text(run.chatTitle,
                                style: neoDisplay(16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(dateStr,
                              style: neoLabel(10,
                                  color: NeoColors.ink
                                      .withValues(alpha: 0.55))),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: widget.onDelete,
                            child: Icon(Icons.delete_outline,
                                size: 16,
                                color: NeoColors.ink.withValues(alpha: 0.4)),
                          ),
                        ],
                      ),

                      // Tag chip (newer export / group)
                      if (hasTag || run.isGroup) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (hasTag)
                              _Chip(
                                label: 'NEWER EXPORT',
                                bg: NeoColors.pink,
                                textColor: NeoColors.ink,
                              ),
                            if (hasTag && run.isGroup)
                              const SizedBox(width: 6),
                            if (run.isGroup)
                              _Chip(
                                label: 'GROUP',
                                bg: NeoColors.lime,
                                textColor: NeoColors.ink,
                              ),
                          ],
                        ),
                      ],

                      // Big stat from headline
                      const SizedBox(height: 10),
                      if (run.headline != null) ...[
                        Text(
                          run.headline!.text,
                          style: neoDisplay(28)
                              .copyWith(height: 1, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${run.messageCount} messages · ${run.personA} & ${run.personB}',
                          style: neoBody(11,
                              color: NeoColors.ink.withValues(alpha: 0.55)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Text(
                          '${_compact(run.messageCount)} msgs',
                          style: neoDisplay(28)
                              .copyWith(height: 1, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${run.personA} & ${run.personB}',
                          style: neoBody(11,
                              color: NeoColors.ink.withValues(alpha: 0.55)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Bottom row: confidence + open arrow
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          _Chip(
                            label: run.notEnoughData
                                ? 'LOW SAMPLE'
                                : 'GOOD SAMPLE',
                            bg: run.notEnoughData
                                ? const Color(0xFFE5E0CF)
                                : NeoColors.lime,
                            textColor: NeoColors.ink,
                          ),
                          const Spacer(),
                          Text('OPEN →',
                              style: neoHeadline(11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  const _Chip({required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: NeoColors.ink, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: neoLabel(9, color: textColor).copyWith(letterSpacing: 0.5),
      ),
    );
  }
}
