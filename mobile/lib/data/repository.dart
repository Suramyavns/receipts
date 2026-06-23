import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/models/analysis_run.dart';
import '../domain/models/run_message.dart';
import '../domain/models/session.dart';
import '../domain/models/metric_result.dart';

class Repository {
  static late Box<String> _runs;
  static late Box<String> _messages;
  static late Box<String> _metrics;
  static late Box<String> _sessions;
  static late Box<String> _settings;

  static Future<void> init() async {
    await Hive.initFlutter();
    _runs = await Hive.openBox<String>('runs_v2');
    _messages = await Hive.openBox<String>('messages_v2');
    _metrics = await Hive.openBox<String>('metrics_v2');
    _sessions = await Hive.openBox<String>('sessions_v2');
    _settings = await Hive.openBox<String>('settings_v2');
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  static bool get isOnboarded => _settings.get('onboarded') == 'true';
  static Future<void> setOnboarded() => _settings.put('onboarded', 'true');

  // ── Runs ──────────────────────────────────────────────────────────────────

  static Future<void> saveRun(
    AnalysisRun run,
    List<RunMessage> messages,
    List<ChatSession> sessions,
    List<MetricResult> metrics,
  ) async {
    await _runs.put(run.id, jsonEncode(run.toJson()));
    await _messages.put(run.id, jsonEncode(messages.map((m) => m.toJson()).toList()));
    await _sessions.put(run.id, jsonEncode(sessions.map((s) => s.toJson()).toList()));
    await _metrics.put(run.id, jsonEncode(metrics.map((m) => m.toJson()).toList()));
  }

  static List<AnalysisRun> allRuns() {
    return _runs.values
        .map((raw) {
          try {
            return AnalysisRun.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<AnalysisRun>()
        .toList()
      ..sort((a, b) => b.importedAt.compareTo(a.importedAt));
  }

  static AnalysisRun? getRun(String runId) {
    final raw = _runs.get(runId);
    if (raw == null) return null;
    try {
      return AnalysisRun.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static bool hashExists(String hash) =>
      _runs.values.any((raw) {
        try {
          final j = jsonDecode(raw) as Map<String, dynamic>;
          return j['sourceHash'] == hash;
        } catch (_) {
          return false;
        }
      });

  /// Returns the run with same chatTitle but a different hash (older export).
  static AnalysisRun? findSameChat(String chatTitle, String excludeHash) {
    for (final raw in _runs.values) {
      try {
        final run = AnalysisRun.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (run.chatTitle == chatTitle && run.sourceHash != excludeHash) return run;
      } catch (_) {}
    }
    return null;
  }

  static Future<void> deleteRun(String runId) async {
    await _runs.delete(runId);
    await _messages.delete(runId);
    await _sessions.delete(runId);
    await _metrics.delete(runId);
  }

  static Future<void> deleteAll() async {
    await _runs.clear();
    await _messages.clear();
    await _sessions.clear();
    await _metrics.clear();
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  static List<RunMessage> getMessages(String runId) {
    final raw = _messages.get(runId);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((j) => RunMessage.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Map<String, RunMessage> getMessageMap(String runId) {
    return {for (final m in getMessages(runId)) m.id: m};
  }

  static List<RunMessage> getMessagesByIds(String runId, List<String> ids) {
    final map = getMessageMap(runId);
    return ids.map((id) => map[id]).whereType<RunMessage>().toList();
  }

  // ── Sessions ──────────────────────────────────────────────────────────────

  static List<ChatSession> getSessions(String runId) {
    final raw = _sessions.get(runId);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((j) => ChatSession.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Metrics ───────────────────────────────────────────────────────────────

  static List<MetricResult> getMetrics(String runId) {
    final raw = _metrics.get(runId);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((j) => MetricResult.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Map<String, MetricResult> getMetricMap(String runId) {
    return {for (final m in getMetrics(runId)) m.metricKey: m};
  }

  static Future<void> saveMetrics(String runId, List<MetricResult> metrics) =>
      _metrics.put(runId, jsonEncode(metrics.map((m) => m.toJson()).toList()));
}
