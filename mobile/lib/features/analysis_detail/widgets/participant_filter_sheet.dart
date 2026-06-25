import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/widgets/primary_button.dart';

class ParticipantFilterSheet extends StatefulWidget {
  final List<String> allParticipants;
  final Set<String> selected;
  final ValueChanged<Set<String>> onApply;

  const ParticipantFilterSheet({
    super.key,
    required this.allParticipants,
    required this.selected,
    required this.onApply,
  });

  @override
  State<ParticipantFilterSheet> createState() => _ParticipantFilterSheetState();
}

class _ParticipantFilterSheetState extends State<ParticipantFilterSheet> {
  late Set<String> _selected;
  String _query = '';
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selected);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.isEmpty) return widget.allParticipants;
    final q = _query.toLowerCase();
    return widget.allParticipants.where((p) => p.toLowerCase().contains(q)).toList();
  }

  bool get _allSelected => _selected.length == widget.allParticipants.length;

  String get _applyLabel {
    if (_selected.isEmpty) return 'SELECT AT LEAST ONE PERSON';
    if (_selected.length == widget.allParticipants.length) {
      return 'VIEW ALL ${_selected.length} PEOPLE';
    }
    if (_selected.length == 1) return 'VIEW ${_selected.first.toUpperCase()}';
    if (_selected.length == 2) return 'COMPARE HEAD-TO-HEAD';
    return 'ANALYZE ${_selected.length} PEOPLE';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Container(
      decoration: const BoxDecoration(
        color: NeoColors.cream,
        border: Border(top: BorderSide(color: NeoColors.ink, width: 3)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: NeoColors.ink.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 12),
            child: Row(
              children: [
                Text('PEOPLE', style: neoDisplay(17)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    if (_allSelected) {
                      _selected.clear();
                    } else {
                      _selected = Set.from(widget.allParticipants);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _allSelected ? NeoColors.ink : NeoColors.surface,
                      border: Border.all(color: NeoColors.ink, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _allSelected ? 'CLEAR ALL' : 'SELECT ALL',
                      style: neoLabel(11,
                          color: _allSelected ? Colors.white : NeoColors.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              decoration: neoBox(bg: NeoColors.surface, offset: 3, radius: 6, borderWidth: 2),
              child: TextField(
                controller: _ctrl,
                onChanged: (v) => setState(() => _query = v),
                style: neoBody(14),
                decoration: InputDecoration(
                  hintText: 'Search participants…',
                  hintStyle: neoBody(14, color: NeoColors.ink.withValues(alpha: 0.4)),
                  prefixIcon: const Icon(Icons.search_rounded, color: NeoColors.ink, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _ctrl.clear();
                            setState(() => _query = '');
                          },
                          child: const Icon(Icons.close_rounded, size: 18, color: NeoColors.ink),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No participants match.',
                        style: neoBody(14, color: NeoColors.ink.withValues(alpha: 0.5))),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      final sel = _selected.contains(p);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (sel) {
                            _selected.remove(p);
                          } else {
                            _selected.add(p);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel ? NeoColors.ink : NeoColors.surface,
                            border: Border.all(color: NeoColors.ink, width: 2),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: sel
                                ? const [BoxShadow(
                                    color: NeoColors.ink,
                                    offset: Offset(3, 3),
                                    blurRadius: 0,
                                  )]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p,
                                  style: neoBody(14,
                                      color: sel ? Colors.white : NeoColors.ink),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (sel)
                                const Icon(Icons.check_rounded,
                                    size: 16, color: Colors.white),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            child: PrimaryButton(
              label: _applyLabel,
              onTap: _selected.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      widget.onApply(Set.from(_selected));
                    },
              bg: NeoColors.blue,
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
