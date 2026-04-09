import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_produto_vendido_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_produto_vendido_forma_pagamento_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/e2e_dependency_bootstrap.dart';

/// Direct repository smoke for the report query used by dashboards.
///
/// This bypasses UI/controller layers and exercises:
/// - client login (when `E2E_CLIENT_EMAIL` / `E2E_CLIENT_PASSWORD` are set)
/// - `POST /agents/commands`
/// - SQL text + named params in
///   `ResumoParcelaProdutoVendidoFormaPagamentoRepositoryImpl`
/// - row parsing into domain entities
void main() {
  group('ResumoParcelaProdutoVendidoFormaPagamentoRepository (e2e)', () {
    test(
      'load executes the real resumo query through the repository',
      () async {
        final missingKeys = missingE2eRepositoryKeys();
        if (missingKeys.isNotEmpty) {
          // Console hint when the full e2e credential set is absent.
          // ignore: avoid_print
          print(
            'SKIP resumo_repository_e2e: missing ${missingKeys.join(', ')}. '
            'Set them in assets/env/local.env, process env, or --dart-define.',
          );
          return;
        }

        await e2eSetupDependencies();
        addTearDown(e2eTeardownDependencies);

        final repository =
            getIt<ResumoParcelaProdutoVendidoFormaPagamentoRepository>();
        final today = DateTime.now();
        final periodEnd = DateTime(today.year, today.month, today.day);
        final periodStart = periodEnd.subtract(const Duration(days: 14));

        final result = await repository.load(
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          filter: ResumoParcelaProdutoVendidoFormaPagamentoFilter(
            dataVendaInicio: periodStart,
            dataVendaFim: periodEnd,
          ),
        );

        result.fold(
          (rows) {
            for (final row in rows) {
              expect(row.nomeUsuario.trim(), isNotEmpty);
              expect(row.descricaoFormaPagamento.trim(), isNotEmpty);
              expect(row.qtdVendas, greaterThanOrEqualTo(0));
              expect(row.valorParcela, isNonNegative);
              expect(row.isAnoMesConsistentWithParts, isTrue);
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
              isKnownInvalidPolicyFailure(failure),
              isTrue,
              reason:
                  'Repository e2e should either return rows or surface '
                  'the known '
                  'invalid_policy classification.',
            );
          },
        );
      },
    );
  });
}
