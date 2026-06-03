import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('direct Agent SQL repositories have matching E2E tests', () {
    final root = Directory.current.path;
    final repositoriesDir = Directory(
      p.join(root, 'lib', 'features', 'agent_queries', 'data', 'repositories'),
    );

    final repositoryFiles =
        repositoriesDir
            .listSync()
            .whereType<File>()
            .where(
              (file) {
                final name = p.basename(file.path);
                return name.endsWith('_repository_impl.dart') ||
                    name.endsWith('_repository_impl_v2.dart');
              },
            )
            .where(_isDirectAgentSqlRepository)
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    final missing = <String>[];
    for (final repositoryFile in repositoryFiles) {
      final repositoryName = _repositoryE2eBaseName(repositoryFile.path);
      final expectedE2e = File(
        p.join(
          root,
          'test',
          'integration',
          'e2e',
          '${repositoryName}_e2e_test.dart',
        ),
      );
      if (!expectedE2e.existsSync()) {
        missing.add(
          '${p.relative(repositoryFile.path, from: root)} -> '
          '${p.relative(expectedE2e.path, from: root)}',
        );
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'Every direct Agent SQL repository must have a matching E2E test:\n'
          '${missing.join('\n')}',
    );
  });
}

bool _isDirectAgentSqlRepository(File file) {
  final source = file.readAsStringSync();
  return source.contains('AgentSqlExecuteRequest(') &&
      (source.contains('AgentSqlRepositoryExecution.execute') ||
          source.contains('.executeSql('));
}

String _repositoryE2eBaseName(String repositoryPath) {
  return p
      .basenameWithoutExtension(repositoryPath)
      .replaceFirst(RegExp(r'_impl_v2$'), '')
      .replaceFirst(RegExp(r'_impl$'), '');
}
