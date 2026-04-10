import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_anual_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/e2e_dependency_bootstrap.dart';

/// Direct repository smoke for the annual parcels by payment method query.
///
/// Same bridge path as ResumoParcelasAnual repository e2e.
void main() {
  group('ResumoParcelasFormaPagamentoAnualRepository (e2e)', () {
    test(
      'load executes the real resumo query through the repository',
      () async {
        final missingKeys = missingE2eRepositoryKeys();
        if (missingKeys.isNotEmpty) {
          // Console hint when the full e2e credential set is absent.
          // ignore: avoid_print
          print(
            'SKIP resumo_parcelas_forma_pagamento_anual_repository_e2e: '
            'missing ${missingKeys.join(', ')}. '
            'Set them in assets/env/local.env, process env, or --dart-define.',
          );
          return;
        }

        await e2eSetupDependencies();
        addTearDown(e2eTeardownDependencies);

        final repository = getIt<ResumoParcelasFormaPagamentoAnualRepository>();
        final today = DateTime.now();
        final periodEnd = DateTime(today.year, today.month, today.day);
        final periodStart = periodEnd.subtract(const Duration(days: 14));

        final result = await repository.load(
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          filter: ResumoParcelasFormaPagamentoAnualFilter(
            dataVendaInicio: periodStart,
            dataVendaFim: periodEnd,
          ),
        );

        result.fold(
          (rows) {
            for (final row in rows) {
              expect(row.ano, greaterThan(1900));
              expect(row.descricaoFormaPagamento, isNotEmpty);
              expect(row.quantidade, greaterThanOrEqualTo(0));
              expect(row.valorTotal, isNonNegative);
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
                  'the known invalid_policy classification.',
            );
          },
        );
      },
    );
  });
}
