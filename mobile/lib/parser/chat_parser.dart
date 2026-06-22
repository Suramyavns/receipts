import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:characters/characters.dart';
import '../domain/models/run_message.dart';
import 'normalizer.dart';

enum ExportFormat { androidDash, iosBracket, unknown }

class ParsedChat {
  final List<RunMessage> messages;
  final ExportFormat format;
  final List<String> participants;
  final bool isGroup;
  final String chatTitle;
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;
  final int mediaCount;
  final int systemCount;

  const ParsedChat({
    required this.messages,
    required this.format,
    required this.participants,
    required this.isGroup,
    required this.chatTitle,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.mediaCount,
    required this.systemCount,
  });
}

class ChatParser {
  static final _androidMsg = RegExp(
    r'^(\d{1,2}/\d{1,2}/\d{2,4}), (\d{1,2}:\d{2}(?::\d{2})?(?: | )?(?:[AaPp][Mm])?) - (.+?): (.*)',
  );
  static final _androidSys = RegExp(
    r'^(\d{1,2}/\d{1,2}/\d{2,4}), (\d{1,2}:\d{2}(?::\d{2})?(?: | )?(?:[AaPp][Mm])?) - (.+)',
  );
  static final _iosMsg = RegExp(
    r'^\[(\d{1,2}/\d{1,2}/\d{2,4}), (\d{1,2}:\d{2}(?::\d{2})?(?:\s?[AaPp][Mm])?)\] (.+?): (.*)',
  );
  static final _iosSys = RegExp(
    r'^\[(\d{1,2}/\d{1,2}/\d{2,4}), (\d{1,2}:\d{2}(?::\d{2})?(?:\s?[AaPp][Mm])?)\] (.+)',
  );

  static Future<ParsedChat> parseFile(String filePath, String runId) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('File not found: $filePath');
    if (filePath.toLowerCase().endsWith('.zip')) {
      return _parseZip(file, runId);
    }
    final text = await file.readAsString();
    return _parseTxt(text, runId);
  }

  static Future<ParsedChat> parseMultipleFiles(List<String> paths, String runId) async {
    String? txtPath;
    for (final p in paths) {
      if (p.toLowerCase().endsWith('.txt')) { txtPath = p; break; }
    }
    if (txtPath == null) throw Exception('No .txt found in shared files');
    final text = await File(txtPath).readAsString();
    return _parseTxt(text, runId);
  }

  static Future<ParsedChat> _parseZip(File zipFile, String runId) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? txtEntry;
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final name = entry.name.split('/').last;
      if (name.endsWith('.txt') && (name == '_chat.txt' || txtEntry == null)) {
        txtEntry = entry;
      }
    }
    if (txtEntry == null) throw Exception('No chat .txt found in ZIP');
    final text = utf8.decode(txtEntry.content as List<int>);
    return _parseTxt(text, runId);
  }

  static ParsedChat _parseTxt(String raw, String runId) {
    final text = Normalizer.normalize(raw);
    final lines = text.split('\n');

    final format = _detectFormat(lines);
    final dayFirst = _inferDayFirst(lines, format);

    final messages = _assembleMessages(lines, format, dayFirst, runId);
    return _buildParsedChat(messages, format, runId);
  }

  static ExportFormat _detectFormat(List<String> lines) {
    int ios = 0, android = 0;
    for (final line in lines.take(50)) {
      if (line.isEmpty) continue;
      if (RegExp(r'^\[\d{1,2}/\d{1,2}/\d{2,4},').hasMatch(line)) {
        ios++;
      } else if (RegExp(r'^\d{1,2}/\d{1,2}/\d{2,4},').hasMatch(line)) {
        android++;
      }
    }
    if (ios > android) return ExportFormat.iosBracket;
    if (android > 0) return ExportFormat.androidDash;
    return ExportFormat.unknown;
  }

  static bool _inferDayFirst(List<String> lines, ExportFormat fmt) {
    final pattern = fmt == ExportFormat.iosBracket
        ? RegExp(r'^\[(\d{1,2})/(\d{1,2})/\d{2,4}')
        : RegExp(r'^(\d{1,2})/(\d{1,2})/\d{2,4}');
    for (final line in lines.take(200)) {
      final m = pattern.firstMatch(line);
      if (m == null) continue;
      final a = int.parse(m.group(1)!);
      final b = int.parse(m.group(2)!);
      if (a > 12) return true;
      if (b > 12) return false;
    }
    return true;
  }

  static List<RunMessage> _assembleMessages(
      List<String> lines, ExportFormat fmt, bool dayFirst, String runId) {
    final messages = <RunMessage>[];
    // Raw accumulator: [dateStr, timeStr, sender, body]
    String? curDate, curTime, curSender, curBody;

    void flush(int idx) {
      if (curDate == null) return;
      final ts = _parseDateTime(curDate, curTime!, dayFirst);
      if (ts == null) return;
      final body = curBody ?? '';
      final stripped = _stripEdited(body);
      final isEdited = stripped != body;
      final kind = _classifyKind(stripped, curSender!);
      final mediaType = kind == MessageKind.media ? _classifyMedia(stripped) : null;
      messages.add(RunMessage(
        id: '${runId}_$idx',
        runId: runId,
        timestamp: ts,
        sender: curSender,
        body: stripped,
        kind: kind,
        mediaType: mediaType,
        isEdited: isEdited,
        wordCount: kind == MessageKind.text ? _countWords(stripped) : 0,
        charCount: kind == MessageKind.text ? stripped.length : 0,
        emojiCount: _countEmojis(stripped),
        hasQuestion: _hasQuestion(stripped),
      ));
    }

    int idx = 0;
    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.isEmpty) continue;

      String? dateStr, timeStr, sender, body;

      if (fmt == ExportFormat.iosBracket || fmt == ExportFormat.unknown) {
        var m = _iosMsg.firstMatch(line);
        if (m != null) {
          dateStr = m.group(1)!; timeStr = m.group(2)!;
          sender = m.group(3)!; body = m.group(4)!;
        } else {
          m = _iosSys.firstMatch(line);
          if (m != null) {
            dateStr = m.group(1)!; timeStr = m.group(2)!;
            sender = ''; body = m.group(3)!;
          }
        }
      }

      if (dateStr == null && (fmt == ExportFormat.androidDash || fmt == ExportFormat.unknown)) {
        var m = _androidMsg.firstMatch(line);
        if (m != null) {
          dateStr = m.group(1)!; timeStr = m.group(2)!;
          sender = m.group(3)!; body = m.group(4)!;
        } else {
          m = _androidSys.firstMatch(line);
          if (m != null) {
            dateStr = m.group(1)!; timeStr = m.group(2)!;
            sender = ''; body = m.group(3)!;
          }
        }
      }

      if (dateStr != null) {
        flush(idx++);
        curDate = dateStr; curTime = timeStr; curSender = sender; curBody = body;
      } else if (curDate != null) {
        curBody = '${curBody ?? ''}\n$line';
      }
    }
    flush(idx);
    return messages;
  }

  static DateTime? _parseDateTime(String dateStr, String timeStr, bool dayFirst) {
    try {
      final dp = dateStr.split('/');
      if (dp.length != 3) return null;
      final int day, month;
      if (dayFirst) {
        day = int.parse(dp[0]); month = int.parse(dp[1]);
      } else {
        month = int.parse(dp[0]); day = int.parse(dp[1]);
      }
      var year = int.parse(dp[2]);
      if (year < 100) year += 2000;

      String t = timeStr.trim();
      bool? isPm;
      if (t.toLowerCase().endsWith('pm')) {
        isPm = true; t = t.substring(0, t.length - 2).trim();
      } else if (t.toLowerCase().endsWith('am')) {
        isPm = false; t = t.substring(0, t.length - 2).trim();
      }

      final tp = t.split(':');
      int h = int.parse(tp[0]);
      final min = int.parse(tp[1]);
      final sec = tp.length > 2 ? int.tryParse(tp[2]) ?? 0 : 0;
      if (isPm == true && h < 12) h += 12;
      if (isPm == false && h == 12) h = 0;

      return DateTime(year, month, day, h, min, sec);
    } catch (_) {
      return null;
    }
  }

  static String _stripEdited(String body) {
    const tag = '<This message was edited>';
    if (body.endsWith(tag)) return body.substring(0, body.length - tag.length).trimRight();
    return body;
  }

  static MessageKind _classifyKind(String body, String sender) {
    if (sender.isEmpty) return MessageKind.system;
    final lo = body.toLowerCase().trim();
    if (lo.isEmpty) return MessageKind.empty;
    if (_isDeleted(lo)) return MessageKind.deleted;
    if (_isMedia(lo)) return MessageKind.media;
    return MessageKind.text;
  }

  static bool _isDeleted(String lo) =>
      lo == 'this message was deleted' || lo == 'you deleted this message';

  static bool _isMedia(String lo) {
    final media = [
      '<media omitted>', 'image omitted', 'video omitted', 'audio omitted',
      'sticker omitted', 'gif omitted', 'document omitted', 'contact card omitted',
      'voice message omitted', 'video note omitted',
    ];
    return media.any((m) => lo == m || lo.startsWith('<attached:'));
  }

  static MediaType _classifyMedia(String lo) {
    if (lo.contains('image') || lo.contains('photo')) return MediaType.photo;
    if (lo.contains('video') || lo.contains('video note')) return MediaType.video;
    if (lo.contains('audio') || lo.contains('voice')) return MediaType.voice;
    if (lo.contains('sticker')) return MediaType.sticker;
    if (lo.contains('gif')) return MediaType.gif;
    if (lo.contains('document')) return MediaType.doc;
    if (lo.contains('contact')) return MediaType.contact;
    return MediaType.photo;
  }

  static int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  static int _countEmojis(String text) {
    return text.characters.where((ch) {
      if (ch.isEmpty) return false;
      final code = ch.runes.first;
      return (code >= 0x1F300 && code <= 0x1FAFF) ||
          (code >= 0x2600 && code <= 0x27BF) ||
          (code >= 0x1F000 && code <= 0x1F02F) ||
          (code >= 0x1F0A0 && code <= 0x1F0FF) ||
          (code >= 0x1F100 && code <= 0x1F1FF);
    }).length;
  }

  static bool _hasQuestion(String text) {
    if (text.contains('?') || text.contains('？')) {
      final noUrls = text.replaceAll(RegExp(r'https?://\S+'), '');
      return noUrls.contains('?') || noUrls.contains('？');
    }
    return false;
  }

  static ParsedChat _buildParsedChat(List<RunMessage> msgs, ExportFormat fmt, String runId) {
    if (msgs.isEmpty) {
      return ParsedChat(
        messages: msgs,
        format: fmt,
        participants: [],
        isGroup: false,
        chatTitle: 'Unknown',
        dateRangeStart: DateTime.now(),
        dateRangeEnd: DateTime.now(),
        mediaCount: 0,
        systemCount: 0,
      );
    }

    final participants = <String>{};
    int mediaCount = 0, systemCount = 0;
    for (final m in msgs) {
      if (m.kind == MessageKind.system) { systemCount++; continue; }
      if (m.sender.isNotEmpty) participants.add(m.sender);
      if (m.kind == MessageKind.media) mediaCount++;
    }

    final sorted = [...msgs]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final isGroup = participants.length > 2;
    final title = _inferTitle(msgs, participants.toList(), isGroup);
    final pList = participants.toList()..sort();

    return ParsedChat(
      messages: msgs,
      format: fmt,
      participants: pList,
      isGroup: isGroup,
      chatTitle: title,
      dateRangeStart: sorted.first.timestamp,
      dateRangeEnd: sorted.last.timestamp,
      mediaCount: mediaCount,
      systemCount: systemCount,
    );
  }

  static String _inferTitle(List<RunMessage> msgs, List<String> participants, bool isGroup) {
    if (isGroup) {
      final groupPattern = RegExp(r'(?:created group|created the group)\s+"(.+?)"', caseSensitive: false);
      for (final m in msgs.take(30)) {
        if (m.kind == MessageKind.system) {
          final match = groupPattern.firstMatch(m.body);
          if (match != null) return match.group(1)!;
        }
      }
      return 'Group Chat';
    }
    return participants.take(2).join(' & ');
  }
}
