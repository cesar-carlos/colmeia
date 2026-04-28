import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

/// Direct repository smoke for the daily-sales filter option queries
/// (vendedor, bairro, municipio autocomplete).
///
/// Each sub-test exercises one of the three option-loading methods so a
/// failure in one does not mask a pass in the others.
void main() {
  group(
    'ResumoVendasDiariasPorVendedorFilterOptionsRepository (e2e)',
    () {
      late DateTime periodStart;
      late DateTime periodEnd;

      setUp(() {
        final today = DateTime.now();
        periodEnd = DateTime(today.year, today.month, today.day);
        periodStart = periodEnd.subtract(const Duration(days: 90));
      });

      test(
        'loadVendedorOptions returns valid seller options',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP resumo_vendas_diarias_filter_options_e2e (vendedor): '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final repository =
              getIt<ResumoVendasDiariasPorVendedorFilterOptionsRepository>();

          final result = await repository.loadVendedorOptions(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            dataVendaInicio: periodStart,
            dataVendaFim: periodEnd,
          );

          result.fold(
            (options) {
              for (final opt in options) {
                expect(opt.codVendedor, greaterThan(0));
                expect(opt.nomeVendedor, isNotEmpty);
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
                    'Repository e2e should return options, invalid_policy / '
                    'missing_permission RPC, or transient bridge HTTP 5xx.',
              );
            },
          );
        },
      );

      test(
        'loadBairroOptions returns valid bairro text options',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP resumo_vendas_diarias_filter_options_e2e (bairro): '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final repository =
              getIt<ResumoVendasDiariasPorVendedorFilterOptionsRepository>();

          final result = await repository.loadBairroOptions(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            dataVendaInicio: periodStart,
            dataVendaFim: periodEnd,
          );

          result.fold(
            (options) {
              for (final opt in options) {
                expect(opt.value, isNotEmpty);
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
                    'Repository e2e should return options, invalid_policy / '
                    'missing_permission RPC, or transient bridge HTTP 5xx.',
              );
            },
          );
        },
      );

      test(
        'loadMunicipioOptions returns valid municipio text options',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP resumo_vendas_diarias_filter_options_e2e (municipio): '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final repository =
              getIt<ResumoVendasDiariasPorVendedorFilterOptionsRepository>();

          final result = await repository.loadMunicipioOptions(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            dataVendaInicio: periodStart,
            dataVendaFim: periodEnd,
          );

          result.fold(
            (options) {
              for (final opt in options) {
                expect(opt.value, isNotEmpty);
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
                    'Repository e2e should return options, invalid_policy / '
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
