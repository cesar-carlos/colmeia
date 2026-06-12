import 'dart:math' as math;

/// Single-line category label: trims and collapses with U+2026 when longer
/// than [maxChars]. Tooltips should keep the full raw string elsewhere.
String formatComparisonBarXAxisLabelCollapsed(
  String raw, {
  required int maxChars,
}) {
  final s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) {
    return s;
  }
  final limit = math.max(4, maxChars);
  if (s.length <= limit) {
    return s;
  }
  return '${s.substring(0, limit)}\u2026';
}

/// Formats a comparison bar category label with word-aware line
/// breaks (`\n`). [maxLines] caps height; overflow on the last line uses U+2026.
///
/// Syncfusion renders `\n` in category axis labels as line breaks.
///
/// When [raw] contains explicit newline characters, each line is truncated
/// independently (no word-wrap merge across lines) so callers can stack
/// structured labels (e.g. date + weekday) without collapsing them.
String formatComparisonBarXAxisLabelWrapped(
  String raw, {
  int maxCharsPerLine = 14,
  int maxLines = 2,
}) {
  final trimmedOuter = raw.trim();
  if (trimmedOuter.contains('\n')) {
    final limit = math.max(4, maxCharsPerLine);
    final capLines = math.max(1, maxLines);
    final segments = trimmedOuter
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final out = <String>[];
    for (var i = 0; i < segments.length && i < capLines; i++) {
      var seg = segments[i];
      if (seg.length > limit) {
        seg = '${seg.substring(0, limit)}\u2026';
      }
      out.add(seg);
    }
    return out.join('\n');
  }

  final s = trimmedOuter.replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) {
    return s;
  }
  final limit = math.max(4, maxCharsPerLine);
  final capLines = math.max(1, maxLines);

  final lines = <String>[];
  var remainder = s;

  while (remainder.isNotEmpty && lines.length < capLines) {
    if (remainder.length <= limit) {
      lines.add(remainder);
      remainder = '';
      break;
    }

    var breakIdx = -1;
    final scanEnd = math.min(limit, remainder.length);
    for (var i = scanEnd - 1; i > 0; i--) {
      if (remainder[i] == ' ') {
        breakIdx = i;
        break;
      }
    }

    late final String line;
    if (breakIdx > 0) {
      line = remainder.substring(0, breakIdx).trimRight();
      remainder = remainder.substring(breakIdx + 1).trimLeft();
    } else {
      line = remainder.substring(0, limit);
      remainder = remainder.substring(limit).trimLeft();
    }

    if (line.isEmpty) {
      lines.add(remainder.substring(0, limit));
      remainder = remainder.length > limit
          ? remainder.substring(limit).trimLeft()
          : '';
      continue;
    }
    lines.add(line);
  }

  if (remainder.isEmpty) {
    return lines.join('\n');
  }

  final lastIdx = lines.length - 1;
  final last = lines[lastIdx];
  final candidate = '$last $remainder'.trim();
  if (candidate.length <= limit) {
    lines[lastIdx] = candidate;
    return lines.join('\n');
  }

  final cap = limit - 1;
  if (last.length >= cap) {
    lines[lastIdx] = '${last.substring(0, cap)}\u2026';
    return lines.join('\n');
  }
  final room = limit - last.length - 1;
  final take = math.max(0, math.min(room, remainder.length));
  final frag = remainder.substring(0, take).trimRight();
  lines[lastIdx] = frag.isEmpty
      ? '${last.substring(0, math.min(cap, last.length))}\u2026'
      : '$last $frag\u2026';
  return lines.join('\n');
}

/// Prefer [formatComparisonBarXAxisLabelWrapped] with `maxLines: 2`.
String formatComparisonBarXAxisLabelTwoLines(
  String raw, {
  int maxCharsPerLine = 14,
}) {
  return formatComparisonBarXAxisLabelWrapped(
    raw,
    maxCharsPerLine: maxCharsPerLine,
  );
}
