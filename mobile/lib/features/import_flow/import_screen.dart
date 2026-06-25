import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import '../../domain/models/analysis_run.dart';
import '../../ingest/ingest_service.dart';
import '../analysis_detail/analysis_detail_screen.dart';
import 'widgets/duplicate_view.dart';
import 'widgets/error_view.dart';
import 'widgets/group_pick_view.dart';
import 'widgets/progress_view.dart';

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

  List<String> _participants = [];
  String? _pickedA;
  String? _pickedB;
  bool _startGroupMode = false;

  final _stepLabels = const [
    'Reading file',
    'Detecting format',
    'Parsing messages',
    'Sessionizing',
    'Crunching stats',
  ];
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run({String? forcedA, String? forcedB}) async {
    setState(() {
      _phase = _Phase.parsing;
      _status = 'Reading file…';
      _stepIndex = 0;
    });
    try {
      final result = await IngestService.ingest(
        widget.filePaths,
        forcedPersonA: forcedA,
        forcedPersonB: forcedB,
        onProgress: (s) {
          if (!mounted) return;
          setState(() {
            _status = s;
            _stepIndex = _stepIndexFor(s);
          });
        },
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AnalysisDetailScreen(
              run: result.run,
              startGroupMode: _startGroupMode,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _phase = _Phase.error; });
      }
    }
  }

  void _analyzeAll() {
    _startGroupMode = true;
    final a = _participants.isNotEmpty ? _participants.first : null;
    final b = _participants.length > 1 ? _participants[1] : _participants.firstOrNull;
    _run(forcedA: a, forcedB: b ?? a);
  }

  int _stepIndexFor(String status) {
    if (status.contains('Detect')) { return 1; }
    if (status.contains('Pars') || status.contains('format')) { return 2; }
    if (status.contains('Session')) { return 3; }
    if (status.contains('Crunch') || status.contains('metric') ||
        status.contains('hash') || status.contains('Saving')) { return 4; }
    return _stepIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.cream,
      body: CustomPaint(
        painter: const DotGridPainter(),
        child: SafeArea(
          child: switch (_phase) {
            _Phase.parsing => ProgressView(
                filePaths: widget.filePaths,
                status: _status,
                stepIndex: _stepIndex,
                stepLabels: _stepLabels,
                onCancel: () => Navigator.pop(context),
              ),
            _Phase.error => ErrorView(
                error: _error ?? 'Unknown error',
                onBack: () => Navigator.pop(context)),
            _Phase.duplicatePrompt => DuplicateView(
                result: _result!,
                onView: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(
                        builder: (_) => AnalysisDetailScreen(
                              run: _result!.run,
                              startGroupMode: _result!.run.isGroup,
                            ))),
                onRerun: () => _run(),
                onBack: () => Navigator.pop(context),
              ),
            _Phase.groupPick => GroupPickView(
                participants: _participants,
                pickedA: _pickedA,
                pickedB: _pickedB,
                onPickedA: (v) => setState(() => _pickedA = v),
                onPickedB: (v) => setState(() => _pickedB = v),
                onConfirm: () => _run(forcedA: _pickedA, forcedB: _pickedB),
                onAnalyzeAll: _analyzeAll,
                onCancel: () => Navigator.pop(context),
              ),
            _Phase.done => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}
