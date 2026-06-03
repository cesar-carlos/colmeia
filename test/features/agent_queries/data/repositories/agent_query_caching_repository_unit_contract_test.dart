import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('caching agent-query repositories have unit test coverage', () {
    final root = Directory.current.path;
    final cachingDir = Directory(
      p.join(
        root,
        'lib',
        'features',
        'agent_queries',
        'data',
        'repositories',
        'caching',
      ),
    );
    final testDir = Directory(
      p.join(
        root,
        'test',
        'features',
        'agent_queries',
        'data',
        'repositories',
        'caching',
      ),
    );

    final implFiles =
        cachingDir
            .listSync()
            .whereType<File>()
            .where(
              (file) =>
                  p.basename(file.path).startsWith('caching_') &&
                  p.basename(file.path).endsWith('_repository_impl.dart'),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    final testSources = <String>[
      for (final file in testDir.listSync().whereType<File>())
        if (file.path.endsWith('_test.dart')) file.readAsStringSync(),
    ];

    final missing = <String>[];
    for (final implFile in implFiles) {
      final className = _cachingRepositoryClassName(implFile.path);
      final dedicatedTest = File(
        p.join(
          testDir.path,
          '${p.basenameWithoutExtension(implFile.path)}_test.dart',
        ),
      );
      final hasDedicatedTest = dedicatedTest.existsSync();
      final referencedInTests = testSources.any(
        (source) => source.contains(className),
      );
      if (!hasDedicatedTest && !referencedInTests) {
        missing.add(
          '${p.relative(implFile.path, from: root)} -> '
          'expected ${p.relative(dedicatedTest.path, from: root)} or '
          'reference to $className in '
          'test/features/agent_queries/data/repositories/caching/',
        );
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'Every caching repository impl must have unit tests:\n'
          '${missing.join('\n')}',
    );
  });
}

String _cachingRepositoryClassName(String implPath) {
  final base = p.basenameWithoutExtension(implPath);
  final parts = base.split('_');
  return parts
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join();
}
