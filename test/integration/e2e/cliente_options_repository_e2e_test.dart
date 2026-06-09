@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cliente_options_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cliente_options_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/cliente_options_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_agent_queries_test_helpers.dart';
import 'support/e2e_name_filter_helpers.dart';

void main() {
  group(
    'ClienteOptionsRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'loadPage executes the real Cliente options query',
        () async {
          if (shouldSkipE2eRepositoryTest(
            'cliente_options_repository_e2e',
          )) {
            return;
          }

          final repository = getIt<ClienteOptionsRepository>();

          final result = await runE2eAppResult(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              filter: const ClienteOptionsFilter(),
              clientToken: AppEnvironment.e2eClientToken,
            ),
          );

          result.fold(
            (page) {
              expect(page.items.length, lessThanOrEqualTo(20));
              expect(page.totalCount, greaterThanOrEqualTo(page.items.length));
              for (final row in page.items) {
                expect(row.codCliente, greaterThan(0));
                expect(row.nomeCliente, isNotEmpty);
                expect(row.nomeMunicipio, isNotEmpty);
                expect(row.ufMunicipio, isNotEmpty);
              }
            },
            (failure) {
              expectAcceptableAgentQueriesE2eFailure(
                failure,
                failureScope: 'Repository e2e',
              );
            },
          );
        },
      );

      test(
        'use case executes the same Cliente options query',
        () async {
          if (shouldSkipE2eRepositoryTest(
            'load_cliente_options use_case e2e',
          )) {
            return;
          }

          final useCase = getIt<LoadClienteOptionsUseCase>();
          final result = await runE2eAppResult(
            () => useCase(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              filter: const ClienteOptionsFilter(page: 2),
              clientToken: AppEnvironment.e2eClientToken,
            ),
          );

          result.fold(
            (page) {
              expect(page.items.length, lessThanOrEqualTo(20));
              for (final row in page.items) {
                expect(row.codCliente, greaterThan(0));
              }
            },
            (failure) {
              expectAcceptableAgentQueriesE2eFailure(
                failure,
                failureScope: 'Use-case e2e',
              );
            },
          );
        },
      );

      test(
        'loadPage applies searchTerm filter when provided',
        () async {
          if (shouldSkipE2eRepositoryTest(
            'cliente_options_repository name-filter e2e',
          )) {
            return;
          }

          final repository = getIt<ClienteOptionsRepository>();
          final baseline = await runE2eAppResult(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              filter: const ClienteOptionsFilter(),
              clientToken: AppEnvironment.e2eClientToken,
            ),
          );

          if (baseline.isError()) {
            final failure = baseline.exceptionOrNull();
            expect(failure, isNotNull);
            expectAcceptableAgentQueriesE2eFailure(
              failure!,
              failureScope: 'Repository e2e',
            );
            return;
          }

          final baselineRows = baseline.getOrThrow().items;
          if (baselineRows.isEmpty) {
            return;
          }

          final filterToken = buildContainsToken(
            baselineRows.first.nomeCliente,
          );
          final filtered = await runE2eAppResultWithHubRetry(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              filter: ClienteOptionsFilter(searchTerm: filterToken),
              clientToken: AppEnvironment.e2eClientToken,
            ),
            actionLabel: 'cliente_options_filtered_loadPage',
            maxAttempts: 4,
          );

          filtered.fold(
            (page) {
              expect(page.items.length, lessThanOrEqualTo(20));
              final upperToken = filterToken.toUpperCase();
              for (final row in page.items) {
                expect(row.codCliente, greaterThan(0));
                final matchesSearch =
                    row.nomeCliente.toUpperCase().contains(upperToken) ||
                    (row.nomeFantasia?.toUpperCase().contains(upperToken) ??
                        false) ||
                    (row.cnpjCpf?.toUpperCase().contains(upperToken) ??
                        false) ||
                    (row.email?.toUpperCase().contains(upperToken) ?? false) ||
                    row.nomeMunicipio.toUpperCase().contains(upperToken) ||
                    (row.codigoIbge?.contains(filterToken) ?? false);
                expect(
                  matchesSearch,
                  isTrue,
                  reason:
                      'Filtered row should match searchTerm on razão social, '
                      'fantasia, CNPJ, e-mail, município, or código IBGE',
                );
              }
            },
            (failure) {
              expectAcceptableAgentQueriesE2eFailure(
                failure,
                failureScope: 'Repository e2e',
              );
            },
          );
        },
      );
    },
    tags: <String>['e2e'],
  );
}
