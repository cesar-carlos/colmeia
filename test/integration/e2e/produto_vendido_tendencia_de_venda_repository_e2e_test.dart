import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'ProdutoVendidoTendenciaDeVendaRepository (e2e)',
    () {
      test(
        'loadAll executes the real trend query through the repository',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // Intentional stdout for local troubleshooting when E2E env is missing.
            // ignore: avoid_print
            print(
              'SKIP produto_vendido_tendencia_de_venda_repository_e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final repository = getIt<ProdutoVendidoTendenciaDeVendaRepository>();

          final result = await repository.loadAll(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: ProdutoVendidoTendenciaDeVendaFilter(
              periodoAtualInicio: DateTime(2026, 3, 1),
              periodoAtualFim: DateTime(2026, 3, 31),
              periodoAnteriorInicio: DateTime(2026, 2, 1),
              periodoAnteriorFim: DateTime(2026, 2, 28),
            ),
          );

          result.fold(
            (rows) {
              for (final row in rows) {
                expect(row.codEmpresa, greaterThan(0));
                expect(row.codFilial, greaterThanOrEqualTo(0));
                expect(row.codProduto, greaterThan(0));
                expect(row.nomeProduto, isNotEmpty);
                expect(row.codUnidadeMedida, isNotEmpty);
                expect(row.qtdAnterior, isNonNegative);
                expect(row.qtdAtual, isNonNegative);
                expect(row.percentualTendencia, isNotNaN);
                expect(row.classificacao, isNotEmpty);
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

      test(
        'use case executes the same trend query (stack path)',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // Intentional stdout for local troubleshooting when E2E env is missing.
            // ignore: avoid_print
            print(
              'SKIP load_produto_vendido_tendencia_de_venda use_case e2e: '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final useCase = getIt<LoadProdutoVendidoTendenciaDeVendaUseCase>();

          final result = await useCase(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: ProdutoVendidoTendenciaDeVendaFilter(
              periodoAtualInicio: DateTime(2026, 3, 1),
              periodoAtualFim: DateTime(2026, 3, 31),
              periodoAnteriorInicio: DateTime(2026, 2, 1),
              periodoAnteriorFim: DateTime(2026, 2, 28),
            ),
          );

          result.fold(
            (rows) {
              for (final row in rows) {
                expect(row.codProduto, greaterThan(0));
                expect(row.classificacao, isNotEmpty);
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
                    'Use-case e2e should return rows, invalid_policy / '
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
