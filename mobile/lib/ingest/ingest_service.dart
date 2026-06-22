import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:file_selector/file_selector.dart';
import '../parser/chat_parser.dart';
import '../domain/sessionizer.dart';
import '../domain/metrics/metrics_runner.dart';
import '../domain/insight/insight_generator.dart';
import '../domain/models/analysis_run.dart';
import '../domain/models/run_message.dart';
import '../data/repository.dart';

enum DedupeStatus { fresh, duplicate, newerExport }

class IngestResult {
  final AnalysisRun run;
  final DedupeStatus dedupeStatus;
  final AnalysisRun? previousRun;

  const IngestResult({
    required this.run,
    required this.dedupeStatus,
    this.previousRun,
  });
}

class IngestService {
  static StreamSubscription<List<SharedFile>>? _sharingSubscription;

  /// Wire up the OS share sheet. Returns any files shared at cold launch.
  static Future<List<String>> init(void Function(List<String>) onFiles) async {
    _sharingSubscription = FlutterSharingIntent.instance.getMediaStream().listen(
      (files) => onFiles(files.map((f) => f.value ?? '').where((p) => p.isNotEmpty).toList()),
    );
    final initial = await FlutterSharingIntent.instance.getInitialSharing();
    return initial.map((f) => f.value ?? '').where((p) => p.isNotEmpty).toList();
  }

  static void dispose() => _sharingSubscription?.cancel();

  static Future<List<String>?> pickFile() async {
    const typeGroup = XTypeGroup(
      label: 'chat exports',
      extensions: ['txt', 'zip'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;
    return [file.path];
  }

  /// Full pipeline: parse → hash → dedupe check → sessionize → metrics → save.
  /// Throws on parse error.
  static Future<IngestResult> ingest(
    List<String> filePaths, {
    String? forcedPersonA,
    String? forcedPersonB,
    void Function(String)? onProgress,
  }) async {
    onProgress?.call('Reading file…');
    final runId = _makeId();

    onProgress?.call('Detecting format…');
    final ParsedChat parsed;
    if (filePaths.length == 1) {
      parsed = await ChatParser.parseFile(filePaths.first, runId);
    } else {
      parsed = await ChatParser.parseMultipleFiles(filePaths, runId);
    }

    onProgress?.call('Computing hash…');
    final hash = _hashMessages(parsed.messages);

    // ── Dedupe check ─────────────────────────────────────────────────────────
    if (Repository.hashExists(hash)) {
      final existing = Repository.allRuns().firstWhere((r) => r.sourceHash == hash);
      return IngestResult(run: existing, dedupeStatus: DedupeStatus.duplicate);
    }
    final previousRun = Repository.findSameChat(parsed.chatTitle, hash);

    // ── Determine A / B ───────────────────────────────────────────────────────
    final pA = forcedPersonA ?? (parsed.participants.isNotEmpty ? parsed.participants.first : '');
    final pB = forcedPersonB ??
        (parsed.participants.length > 1 ? parsed.participants[1] : pA);

    onProgress?.call('Sessionizing…');
    final sessions = Sessionizer.sessionize(parsed.messages, runId);

    onProgress?.call('Crunching metrics…');
    final metricsList = await MetricsRunner.run(
      runId: runId,
      personA: pA,
      personB: pB,
      messages: parsed.messages,
      sessions: sessions,
    );

    // ── Build headline from most impactful result ────────────────────────────
    final metricMap = {for (final m in metricsList) m.metricKey: m};
    final insights = InsightGenerator.generate(pA, pB, metricMap);
    final headlineStat = insights.isNotEmpty
        ? HeadlineStat(key: insights.first.metricKey, text: insights.first.text)
        : null;

    final userMsgCount = parsed.messages.where((m) => m.isUserMessage).length;

    final run = AnalysisRun(
      id: runId,
      importedAt: DateTime.now(),
      chatTitle: parsed.chatTitle,
      isGroup: parsed.isGroup,
      participants: parsed.participants,
      personA: pA,
      personB: pB,
      messageCount: userMsgCount,
      mediaCount: parsed.mediaCount,
      systemCount: parsed.systemCount,
      dateRangeStart: parsed.dateRangeStart,
      dateRangeEnd: parsed.dateRangeEnd,
      sourceHash: hash,
      exportFormat: parsed.format == ExportFormat.iosBracket ? 'iosBracket' : 'androidDash',
      headline: headlineStat,
      notEnoughData: userMsgCount < 20,
    );

    onProgress?.call('Saving…');
    await Repository.saveRun(run, parsed.messages, sessions, metricsList);

    return IngestResult(
      run: run,
      dedupeStatus: previousRun != null ? DedupeStatus.newerExport : DedupeStatus.fresh,
      previousRun: previousRun,
    );
  }

  static String _makeId() =>
      DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
      _rand().toRadixString(36);

  static int _rand() => DateTime.now().microsecondsSinceEpoch & 0xFFFF;

  static String _hashMessages(List<RunMessage> msgs) {
    final content = msgs
        .where((m) => m.isUserMessage)
        .map((m) => '${m.timestamp.millisecondsSinceEpoch}|${m.sender}|${m.body}')
        .join('\n');
    final bytes = utf8.encode(content);
    return sha256.convert(bytes).toString();
  }
}
