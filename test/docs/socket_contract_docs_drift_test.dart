import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('socket contract docs drift guards', () {
    test('do not document compat as the connection:ready default', () {
      final violations = <String>[];
      for (final file in _contractTextFiles()) {
        final relativePath = file.path.replaceAll(r'\', '/');
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i += 1) {
          final line = lines[i];
          for (final pattern in _forbiddenCompatDefaultPatterns) {
            if (pattern.hasMatch(line)) {
              violations.add('$relativePath:${i + 1}: $line');
            }
          }
        }
      }

      check(violations).isEmpty();
    });

    test('root socket summary keeps legacy removal contract visible', () {
      final rootSummary = File(
        'docs/plug_server_docs_index_for_colmeia.md',
      ).readAsStringSync();

      check(rootSummary).contains('2026-09-30');
      check(rootSummary).contains('payload_frame_only');
      check(rootSummary).contains('plug-jsonrpc-profile/2.10');
      check(rootSummary).contains('prefer_db_streaming');
      check(rootSummary).contains('max_parallel_read_only_batch_items');
      check(rootSummary).contains('AGENT_SQL_CACHE_TTL_MS');
      check(rootSummary).contains(
        'AGENT_SQL_OVERVIEW_BATCH_MAX_PARALLEL_READ_ONLY_ITEMS',
      );
      check(rootSummary).contains(
        'AGENT_SQL_RELAY_STREAMING_MAX_CONCURRENT_PER_AGENT',
      );
      check(rootSummary).contains(
        'SOCKET_PROFILE_UPDATED_LEGACY_RAW_JSON_ENABLED',
      );
      check(rootSummary).contains('Legacy removal plan');
    });
  });
}

final List<RegExp> _forbiddenCompatDefaultPatterns = <RegExp>[
  RegExp(r'compat\s*\(default\)', caseSensitive: false),
  RegExp(r'compat\s+default', caseSensitive: false),
  RegExp(r'compat\s+por\s+padr', caseSensitive: false),
  RegExp(
    'compat.*safe choice during the migration window',
    caseSensitive: false,
  ),
];

Iterable<File> _contractTextFiles() sync* {
  for (final path in <String>[
    'assets/env/.env.example',
    'assets/env/default.env',
    '.github/workflows/flutter_e2e.yml',
  ]) {
    yield File(path);
  }

  final docs = Directory('docs');
  if (!docs.existsSync()) {
    return;
  }
  for (final entity in docs.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.md')) {
      yield entity;
    }
  }
}
