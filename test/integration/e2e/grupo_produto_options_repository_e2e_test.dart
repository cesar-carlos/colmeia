import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/application/usecases/load_grupo_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/grupo_produto_options_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';
import 'support/e2e_name_filter_helpers.dart';

void main() {
  group(
    'GrupoProdutoOptionsRepository (e2e)',
    () {
      test(
        'loadAll executes the real GrupoProduto options query',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP grupo_produto_options_repository_e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final repository = getIt<GrupoProdutoOptionsRepository>();

          final result = await repository.loadAll(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
          );

          result.fold(
            (rows) {
              expect(rows.length, lessThanOrEqualTo(20));
              for (final row in rows) {
                expect(row.codGrupoProduto, greaterThan(0));
                expect(row.nomeGrupoProduto, isNotEmpty);
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
        'use case executes the same GrupoProduto options query',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP load_grupo_produto_options use_case e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final useCase = getIt<LoadGrupoProdutoOptionsUseCase>();
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
                expect(row.codGrupoProduto, greaterThan(0));
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

      test(
        'loadAll applies searchTerm filter when provided',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP grupo_produto_options_repository name-filter e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final repository = getIt<GrupoProdutoOptionsRepository>();
          final baseline = await repository.loadAll(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
          );

          if (baseline.isError()) {
            final failure = baseline.exceptionOrNull();
            expect(
              failure,
              isNot(isA<SessionFailure>()),
              reason:
                  'Unexpected HTTP 401 after client login '
                  '— check E2E_* values.',
            );
            expect(
              failure != null &&
                  isAcceptableE2eAgentSqlRepositoryFailure(failure),
              isTrue,
              reason:
                  'Repository e2e should return rows, invalid_policy / '
                  'missing_permission RPC, or transient bridge HTTP 5xx.',
            );
            return;
          }

          final baselineRows = baseline.getOrThrow();
          if (baselineRows.isEmpty) {
            return;
          }

          final filterToken = buildContainsToken(
            baselineRows.first.nomeGrupoProduto,
          );
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
                expect(row.codGrupoProduto, greaterThan(0));
                expect(
                  row.nomeGrupoProduto.toUpperCase(),
                  contains(filterToken.toUpperCase()),
                );
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
