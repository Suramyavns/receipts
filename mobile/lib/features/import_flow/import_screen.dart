import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import '../../domain/models/analysis_run.dart';
import '../../ingest/ingest_service.dart';
import '../../shared/widgets/neo_button.dart';
import '../../shared/widgets/neo_card.dart';
import '../analysis_detail/analysis_detail_screen.dart';

class ImportScreen extends StatefulWidget {
  final List<String> filePaths;
  final void Function(AnalysisRun)? onComplete;

  const ImportScreen({super.key, required this.filePaths, this.onComplete});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

enum _Phase { parsing, groupPick, duplicatePrompt, error, done }

class _ImportScreenState extends State<ImportScreen> {
  _Phase _phase = _Phase.parsing;
  String _status = 'Reading file…';
  String? _error;
  IngestResult? _result;

  // For group A/B picker
  List<String> _participants = [];
  String? _pickedA;
  String? _pickedB;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run({String? forcedA, String? forcedB}) async {
    setState(() { _phase = _Phase.parsing; _status = 'Reading file…'; });
    try {
      final result = await IngestService.ingest(
        widget.filePaths,
        forcedPersonA: forcedA,
        forcedPersonB: forcedB,
        onProgress: (s) { if (mounted) setState(() => _status = s); },
      );

      if (!mounted) return;

      if (result.dedupeStatus == DedupeStatus.duplicate) {
        setState(() { _result = result; _phase = _Phase.duplicatePrompt; });
        return;
      }

      if (result.run.isGroup && forcedA == null) {
        setState(() {
          _result = result;
          _participants = result.run.participants;
          _pickedA = _participants.isNotEmpty ? _participants.first : null;
          _pickedB = _participants.length > 1 ? _participants[1] : null;
          _phase = _Phase.groupPick;
        });
        return;
      }

      setState(() { _result = result; _phase = _Phase.done; });
      widget.onComplete?.call(result.run);
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => AnalysisDetailScreen(run: result.run)));
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _phase = _Phase.error; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.cream,
      appBar: AppBar(title: Text('Import Chat', style: neoHeadline(18))),
      body: switch (_phase) {
        _Phase.parsing => _ParsingView(status: _status),
        _Phase.error => _ErrorView(error: _error ?? 'Unknown error',
            onBack: () => Navigator.pop(context)),
        _Phase.duplicatePrompt => _DuplicateView(
            result: _result!,
            onView: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => AnalysisDetailScreen(run: _result!.run))),
            onRerun: () => _run(),
            onBack: () => Navigator.pop(context),
          ),
        _Phase.groupPick => _GroupPickView(
            participants: _participants,
            pickedA: _pickedA,
            pickedB: _pickedB,
            onPickedA: (v) => setState(() => _pickedA = v),
            onPickedB: (v) => setState(() => _pickedB = v),
            onConfirm: () => _run(forcedA: _pickedA, forcedB: _pickedB),
          ),
        _Phase.done => const SizedBox.shrink(),
      },
    );
  }
}

class _ParsingView extends StatelessWidget {
  final String status;
  const _ParsingView({required this.status});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: neoBox(bg: NeoColors.yellow),
              child: const Center(
                  child: CircularProgressIndicator(
                      color: NeoColors.ink, strokeWidth: 2.5)),
            ),
            const SizedBox(height: 24),
            Text(status, style: neoHeadline(18), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Everything stays on your phone.',
                style: neoBody(13,
                    color: NeoColors.ink.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onBack;
  const _ErrorView({required this.error, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NeoCard(
            bg: NeoColors.pink.withValues(alpha: 0.2),
            child: Column(children: [
              Text('Parse error', style: neoHeadline(18)),
              const SizedBox(height: 8),
              Text(error, style: neoBody(13)),
            ]),
          ),
          const SizedBox(height: 24),
          NeoButton(label: 'Go back', onPressed: onBack),
        ],
      ),
    );
  }
}

class _DuplicateView extends StatelessWidget {
  final IngestResult result;
  final VoidCallback onView, onRerun, onBack;
  const _DuplicateView({
    required this.result,
    required this.onView,
    required this.onRerun,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isNewer = result.dedupeStatus == DedupeStatus.newerExport;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NeoCard(
            bg: NeoColors.yellow,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isNewer ? 'Newer export detected' : 'Already analysed',
                style: neoHeadline(18),
              ),
              const SizedBox(height: 8),
              Text(
                isNewer
                    ? 'This looks like a newer export of "${result.run.chatTitle}". Re-run to update stats?'
                    : "You've already analysed this exact export.",
                style: neoBody(14),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          NeoButton(label: 'View existing', onPressed: onView),
          const SizedBox(height: 12),
          if (isNewer) ...[
            NeoButton(
                label: 'Re-run with new data',
                onPressed: onRerun,
                accent: NeoColors.lime),
            const SizedBox(height: 12),
          ],
          NeoButton(
              label: 'Cancel',
              onPressed: onBack,
              accent: NeoColors.surface),
        ],
      ),
    );
  }
}

class _GroupPickView extends StatelessWidget {
  final List<String> participants;
  final String? pickedA, pickedB;
  final ValueChanged<String> onPickedA, onPickedB;
  final VoidCallback onConfirm;

  const _GroupPickView({
    required this.participants,
    required this.pickedA,
    required this.pickedB,
    required this.onPickedA,
    required this.onPickedB,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final canConfirm = pickedA != null && pickedB != null && pickedA != pickedB;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Group chat detected', style: neoDisplay(24)),
          const SizedBox(height: 8),
          Text('Pick two people to compare head-to-head.',
              style: neoBody(15, color: NeoColors.ink.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          Text('Person A', style: neoHeadline(14)),
          const SizedBox(height: 8),
          _PersonPicker(
              participants: participants,
              selected: pickedA,
              exclude: pickedB,
              accent: NeoColors.blue,
              onSelected: onPickedA),
          const SizedBox(height: 20),
          Text('Person B', style: neoHeadline(14)),
          const SizedBox(height: 8),
          _PersonPicker(
              participants: participants,
              selected: pickedB,
              exclude: pickedA,
              accent: NeoColors.pink,
              onSelected: onPickedB),
          const SizedBox(height: 32),
          NeoButton(
              label: canConfirm
                  ? 'Compare $pickedA vs $pickedB'
                  : 'Pick two different people',
              onPressed: canConfirm ? onConfirm : null),
        ],
      ),
    );
  }
}

class _PersonPicker extends StatelessWidget {
  final List<String> participants;
  final String? selected, exclude;
  final Color accent;
  final ValueChanged<String> onSelected;

  const _PersonPicker({
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
                  ? [
                      const BoxShadow(
                          color: NeoColors.ink,
                          offset: Offset(3, 3),
                          blurRadius: 0)
                    ]
                  : [],
            ),
            child: Text(p, style: neoBody(14)),
          ),
        );
      }).toList(),
    );
  }
}
