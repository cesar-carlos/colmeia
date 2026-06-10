import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('across-agent repositories have matching E2E coverage', () {
    final root = Directory.current.path;
    final repositoriesDir = Directory(
      p.join(root, 'lib', 'features', 'agent_queries', 'data', 'repositories'),
    );
    final e2eDir = Directory(p.join(root, 'test', 'integration', 'e2e'));
    final e2eFiles =
        e2eDir
            .listSync()
            .whereType<File>()
            .where((file) => p.basename(file.path).endsWith('_e2e_test.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final e2eSources = <String, String>{
      for (final file in e2eFiles)
        p.basename(file.path): file.readAsStringSync(),
    };

    final repositoryFiles = repositoriesDir.listSync().whereType<File>().where(
      (file) {
        final name = p.basename(file.path);
        return name.endsWith('_across_agents_repository_impl.dart') ||
            name.endsWith('_across_agents_repository_impl_v2.dart');
      },
    ).toList()..sort((a, b) => a.path.compareTo(b.path));

    final missing = <String>[];
    for (final repositoryFile in repositoryFiles) {
      final repositoryName = _acrossAgentsRepositoryE2eBaseName(
        repositoryFile.path,
      );
      final expectedFileNames = <String>{
        '${repositoryName}_e2e_test.dart',
        'load_${repositoryName}_e2e_test.dart',
      };
      final expectedSymbols = _expectedUseCaseSymbols(repositoryName);
      final hasNamedFile = e2eSources.keys.any(expectedFileNames.contains);
      final missingSymbols = expectedSymbols
          .where(
            (symbol) =>
                !e2eSources.values.any((source) => source.contains(symbol)),
          )
          .toList(growable: false);
      final hasSymbolCoverage = missingSymbols.isEmpty;

      if (!hasNamedFile && !hasSymbolCoverage) {
        final symbolMessage = missingSymbols.length == expectedSymbols.length
            ? 'expected symbol ${expectedSymbols.join(' / ')}'
            : 'missing symbol ${missingSymbols.join(' / ')}';
        missing.add(
          '${p.relative(repositoryFile.path, from: root)} -> '
          'expected one of ${expectedFileNames.join(', ')} or $symbolMessage '
          'in E2E tests',
        );
      } else if (hasNamedFile && missingSymbols.isNotEmpty) {
        missing.add(
          '${p.relative(repositoryFile.path, from: root)} -> '
          'named E2E file exists, but ${missingSymbols.join(' / ')} '
          'is not referenced by any E2E test',
        );
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'Every across-agent repository must be exercised by E2E coverage:\n'
          '${missing.join('\n')}',
    );
  });
}

List<String> _expectedUseCaseSymbols(String repositoryName) {
  if (repositoryName ==
      'resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository') {
    return const <String>[
      'LoadResumoVendasDiariasPorVendedorVendedorOptionsAcrossAgentsUseCase',
      'LoadResumoVendasDiariasPorVendedorBairroOptionsAcrossAgentsUseCase',
      'LoadResumoVendasDiariasPorVendedorMunicipioOptionsAcrossAgentsUseCase',
    ];
  }

  final isV2 = repositoryName.endsWith('_repository_v2');
  final useCaseName = repositoryName
      .replaceFirst(RegExp(r'_repository_v2$'), '')
      .replaceFirst(RegExp(r'_repository$'), '');
  final suffix = isV2 ? 'UseCaseV2' : 'UseCase';
  return <String>['Load${_snakeToPascal(useCaseName)}$suffix'];
}

String _acrossAgentsRepositoryE2eBaseName(String repositoryPath) {
  return p
      .basenameWithoutExtension(repositoryPath)
      .replaceFirst(RegExp(r'_impl_v2$'), '')
      .replaceFirst(RegExp(r'_impl$'), '');
}

String _snakeToPascal(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join();
}
