import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hub/agent validators may reject `/* */` in SQL payloads. Scan only
/// `lib/features/agent_queries/data/queries/*_sql.dart` (excludes
/// `*_expression.dart` helpers) and only inspect Dart string *literals*
/// (triple-quoted and simple single-quoted `static const String` values) so
/// `/*` in line comments outside literals does not false-positive.
void main() {
  test('agent query SQL literals must not contain block comment openers', () {
    final root = _packageRootDirectory();
    final queriesDir = Directory(
      '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}'
      'features${Platform.pathSeparator}agent_queries${Platform.pathSeparator}'
      'data${Platform.pathSeparator}queries',
    );
    expect(queriesDir.existsSync(), isTrue, reason: queriesDir.path);

    final sqlSources =
        queriesDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('_sql.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(
      sqlSources.length,
      greaterThanOrEqualTo(25),
      reason: 'Expected a stable catalog of *_sql.dart sources under queries/',
    );

    final violations = <String>[];
    for (final file in sqlSources) {
      final text = file.readAsStringSync();
      for (final literal in _sqlStringLiteralsFromSource(text)) {
        if (literal.contains('/*')) {
          violations.add('${file.uri.pathSegments.last}: …$literal…');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Remove /* */ from SQL string literals sent to the bridge:\n'
          '${violations.join('\n')}',
    );
  });
}

Directory _packageRootDirectory() {
  var current = Directory.current;
  while (true) {
    final pubspec = File(
      '${current.path}${Platform.pathSeparator}pubspec.yaml',
    );
    if (pubspec.existsSync()) return current;
    final parent = current.parent;
    if (parent.path == current.path) {
      fail('Could not locate pubspec.yaml from ${Directory.current.path}');
    }
    current = parent;
  }
}

Iterable<String> _sqlStringLiteralsFromSource(String text) sync* {
  for (final Match m in _tripleQuoted.allMatches(text)) {
    yield m.group(1)!;
  }
  for (final Match m in _singleQuotedStaticConst.allMatches(text)) {
    final single = m.group(1) ?? m.group(2);
    if (single != null) yield single;
  }
}

final RegExp _tripleQuoted = RegExp(r"'''([\s\S]*?)'''", multiLine: true);

/// `static const String x = '...';` or the opening quote on the line after `=`.
final RegExp _singleQuotedStaticConst = RegExp(
  r"static const String\s+\w+\s*=\s*(?:'((?:[^'\\]|\\.)*)'\s*;|\r?\n\s*'((?:[^'\\]|\\.)*)'\s*;)",
  multiLine: true,
);
