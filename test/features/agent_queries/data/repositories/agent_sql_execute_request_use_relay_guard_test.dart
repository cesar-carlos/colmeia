import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agent query repositories declare useRelay on every SQL request', () {
    final root = Directory('lib/features/agent_queries/data/repositories');
    final missing = <String>[];

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final text = entity.readAsStringSync();
      final matches = RegExp(
        r'AgentSqlExecuteRequest\([\s\S]*?\);',
      ).allMatches(text);

      for (final match in matches) {
        final source = match.group(0)!;
        if (source.contains(RegExp(r'useRelay\s*:'))) {
          continue;
        }
        final line = '\n'.allMatches(text.substring(0, match.start)).length + 1;
        missing.add('${entity.path}:$line');
      }
    }

    check(missing).isEmpty();
  });
}
