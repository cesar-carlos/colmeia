import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_marca_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/marca_produto_options_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_agent_queries_test_helpers.dart';
import 'support/e2e_name_filter_helpers.dart';

void main() {
  group(
    'MarcaProdutoOptionsRepository (e2e)',
    () {
      test(
        'loadAll executes the real Marca options query',
        () async {
          if (shouldSkipE2eRepositoryTest(
            'marca_produto_options_repository_e2e',
          )) {
            return;
          }

          await setupE2eDependenciesWithTearDown();

          final repository = getIt<MarcaProdutoOptionsRepository>();

          final result = await repository.loadAll(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
          );

          result.fold(
            (rows) {
              expect(rows.length, lessThanOrEqualTo(20));
              for (final row in rows) {
                expect(row.codMarca, greaterThan(0));
                expect(row.nomeMarca, isNotEmpty);
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
        'use case executes the same Marca options query',
        () async {
          if (shouldSkipE2eRepositoryTest(
            'load_marca_produto_options use_case e2e',
          )) {
            return;
          }

          await setupE2eDependenciesWithTearDown();

          final useCase = getIt<LoadMarcaProdutoOptionsUseCase>();
          final result = await useCase(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            page: 2,
            clientToken: AppEnvironment.e2eClientToken,
          );

          result.fold(
            (rows) {
              expect(rows.length, lessThanOrEqualTo(20));
              for (final row in rows) {
                expect(row.codMarca, greaterThan(0));
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
        'loadAll applies searchTerm filter when provided',
        () async {
          if (shouldSkipE2eRepositoryTest(
            'marca_produto_options_repository name-filter e2e',
          )) {
            return;
          }

          await setupE2eDependenciesWithTearDown();

          final repository = getIt<MarcaProdutoOptionsRepository>();
          final baseline = await repository.loadAll(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
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

          final baselineRows = baseline.getOrThrow();
          if (baselineRows.isEmpty) {
            return;
          }

          final filterToken = buildContainsToken(baselineRows.first.nomeMarca);
          final filtered = await repository.loadAll(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            searchTerm: filterToken,
            clientToken: AppEnvironment.e2eClientToken,
          );

          filtered.fold(
            (rows) {
              expect(rows.length, lessThanOrEqualTo(20));
              for (final row in rows) {
                expect(row.codMarca, greaterThan(0));
                expect(
                  row.nomeMarca.toUpperCase(),
                  contains(filterToken.toUpperCase()),
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
