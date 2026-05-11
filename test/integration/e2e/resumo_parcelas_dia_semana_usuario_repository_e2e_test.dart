@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_usuario_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'ResumoParcelasDiaSemanaUsuarioRepository (e2e)',
    () {
      test(
        'load executes the real resumo query through the repository',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // Skip path must log to stdout so local runs explain missing env.
            // ignore: avoid_print
            print(
              'SKIP resumo_parcelas_dia_semana_usuario_repository_e2e: '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final repository = getIt<ResumoParcelasDiaSemanaUsuarioRepository>();
          final today = DateTime.now();
          final periodEnd = DateTime(today.year, today.month, today.day);
          final periodStart = periodEnd.subtract(const Duration(days: 14));

          final result = await runE2eAppResult(
            () => repository.load(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: ResumoParcelasDiaSemanaFilter(
                dataVendaInicio: periodStart,
                dataVendaFim: periodEnd,
              ),
            ),
          );

          result.fold(
            (rows) {
              for (final row in rows) {
                expect(row.diaSemana, isNotEmpty);
                expect(row.nomeUsuario, isNotEmpty);
                expect(row.diaSemanaNumero, inInclusiveRange(1, 7));
                expect(row.qtdVendas, greaterThanOrEqualTo(0));
                expect(row.valorParcela, isNonNegative);
              }
            },
            (failure) {
              expect(
                failure,
                isNot(isA<SessionFailure>()),
                reason:
                    'Unexpected HTTP 401 after client login '
                    '— check E2E_* values.',
              );
              expect(
                isAcceptableE2eAgentSqlRepositoryFailure(failure),
                isTrue,
                reason:
                    'Repository e2e should return rows, invalid_policy / '
                    'missing_permission RPC, or transient bridge HTTP 5xx.',
              );
            },
          );
        },
      );
    },
    tags: <String>['e2e'],
  );
}
