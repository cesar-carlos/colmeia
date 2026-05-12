@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_periodo_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'ResumoTotalVendasMunicipioFilialPeriodoRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test('load executes the real period query through the repository', () async {
        final missingKeys = missingE2eRepositoryKeys();
        if (missingKeys.isNotEmpty) {
          // ignore: avoid_print, reason: E2E skip reason must be visible in CLI output.
          print(
            'SKIP resumo_total_vendas_municipio_filial_periodo_repository_e2e: '
            'missing ${missingKeys.join(', ')}. '
            'Set them in assets/env/local.env, process env, or --dart-define.',
          );
          return;
        }

        final repository =
            getIt<ResumoTotalVendasMunicipioFilialPeriodoRepository>();
        final today = DateTime.now();
        final periodEnd = DateTime(today.year, today.month, today.day);
        final periodStart = periodEnd.subtract(const Duration(days: 14));

        final result = await runE2eAppResult(
          () => repository.load(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: ResumoTotalVendasMunicipioFilialPeriodoFilter(
              dataVendaInicio: periodStart,
              dataVendaFim: periodEnd,
            ),
          ),
        );

        result.fold(
          (loadedRows) {
            expect(loadedRows.sourceRowCount, greaterThanOrEqualTo(0));
            for (final row in loadedRows.rows) {
              expect(row.codEmpresa, greaterThan(0));
              expect(row.codFilial, greaterThanOrEqualTo(0));
              expect(row.nomeFilial, isNotEmpty);
              final codMunicipio = row.codMunicipioFilial;
              if (codMunicipio != null) {
                expect(codMunicipio, greaterThan(0));
              }
              final municipio = row.nomeMunicipioFilial;
              if (municipio != null) {
                expect(municipio, isNotEmpty);
              }
              final uf = row.ufMunicipioFilial;
              if (uf != null) {
                expect(uf, isNotEmpty);
              }
              expect(row.qtdVendas, greaterThanOrEqualTo(0));
              expect(row.totalVenda, isNonNegative);
              final fantasia = row.nomeFantasiaFilial;
              if (fantasia != null) {
                expect(fantasia, isNotEmpty);
              }
              final cep = row.cepFilial;
              if (cep != null) {
                expect(cep, isNotEmpty);
              }
              final ibge = row.codigoIbgeMunicipioFilial;
              if (ibge != null) {
                expect(ibge, matches(RegExp(r'^\d{7}$')));
              }
            }
          },
          (failure) {
            expect(
              failure,
              isNot(isA<SessionFailure>()),
              reason:
                  'Unexpected HTTP 401 after client login '
                  '-- check E2E_* values.',
            );
            expect(
              isAcceptableE2eAgentSqlRepositoryFailure(failure),
              isTrue,
              reason:
                  'Repository e2e should return rows, invalid_policy / '
                  'missing_permission RPC, transient transport, queue '
                  'saturation, or transient bridge HTTP 5xx.',
            );
          },
        );
      });
    },
    tags: <String>['e2e'],
  );
}
