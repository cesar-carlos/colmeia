@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_ranking_produtos_faturamento_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_load_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/ranking_produtos_faturamento_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'RankingProdutosFaturamentoRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      final periodStart = DateTime(2026);
      final periodEnd = DateTime(2026, 3, 31);

      int branchKey(RankingProdutosFaturamentoRow row) =>
          row.codEmpresa * 100000 + row.codFilial;

      Map<int, List<RankingProdutosFaturamentoRow>> groupByBranch(
        List<RankingProdutosFaturamentoRow> rows,
      ) {
        final grouped = <int, List<RankingProdutosFaturamentoRow>>{};
        for (final row in rows) {
          grouped.putIfAbsent(branchKey(row), () => <RankingProdutosFaturamentoRow>[]).add(row);
        }
        return grouped;
      }

      void assertRankingLoadResult(
        RankingProdutosFaturamentoLoadResult loadResult, {
        required int maxQuantidadeProdutos,
        int? expectedCodEmpresa,
        int? expectedCodFilial,
      }) {
        final rows = loadResult.rows;
        final branches = groupByBranch(rows);
        final branchCount = branches.length;

        expect(
          rows.length,
          lessThanOrEqualTo((maxQuantidadeProdutos + 1) * branchCount),
        );

        for (final branchRows in branches.values) {
          final diversosRows =
              branchRows.where((row) => row.isDiversos).toList();
          expect(diversosRows.length, lessThanOrEqualTo(1));

          final rankedRows =
              branchRows.where((row) => !row.isDiversos).toList();
          for (final row in rankedRows) {
            expect(row.valorVenda, isNonNegative);
            expect(row.percentual, inInclusiveRange(0, 100));
            expect(row.codProduto, greaterThan(0));
            expect(row.nomeProduto, isNotEmpty);
            if (row.posicao != null) {
              expect(row.posicao, inInclusiveRange(1, maxQuantidadeProdutos));
            }
          }

          for (final row in diversosRows) {
            expect(row.valorVenda, greaterThan(0));
            expect(row.codProduto, 0);
            expect(row.nomeProduto, RankingProdutosFaturamentoRow.diversosNomeProduto);
            expect(row.posicao, isNull);
            expect(row.codEmpresa, isNot(9999));
            expect(row.codFilial, isNot(9999));
          }

          if (branchRows.length >= 2) {
            final percentSum = branchRows.fold<double>(
              0,
              (sum, row) => sum + row.percentual,
            );
            expect(percentSum, inInclusiveRange(99.0, 101.0));
          }

          if (diversosRows.isNotEmpty && rankedRows.isNotEmpty) {
            expect(branchRows.last.isDiversos, isTrue);
          }
        }

        if (expectedCodEmpresa != null) {
          expect(
            rows.every((row) => row.codEmpresa == expectedCodEmpresa),
            isTrue,
          );
        }
        if (expectedCodFilial != null) {
          expect(
            rows.every((row) => row.codFilial == expectedCodFilial),
            isTrue,
          );
        }
      }

      void assertAcceptableFailure(AppFailure failure) {
        expect(
          failure,
          isNot(isA<SessionFailure>()),
          reason:
              'Unexpected HTTP 401 after client login — check E2E_* values.',
        );
        expect(
          isAcceptableE2eAgentSqlRepositoryFailure(failure),
          isTrue,
          reason:
              'Repository e2e should return rows, invalid_policy / '
              'missing_permission RPC, or transient bridge HTTP 5xx.',
        );
      }

      test(
        'load with quantidadeProdutos 15 executes the real ranking query',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP ranking_produtos_faturamento_repository_e2e (top 15): '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final repository = getIt<RankingProdutosFaturamentoRepository>();

          final result = await runE2eAppResult(
            () => repository.load(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: RankingProdutosFaturamentoFilter(
                dataVendaInicio: periodStart,
                dataVendaFim: periodEnd,
                quantidadeProdutos: 15,
              ),
            ),
          );

          result.fold(
            (loadResult) => assertRankingLoadResult(
              loadResult,
              maxQuantidadeProdutos: 15,
            ),
            assertAcceptableFailure,
          );
        },
      );

      test(
        'load with quantidadeProdutos 5 respects per-branch row cap',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP ranking_produtos_faturamento_repository_e2e (top 5): '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final repository = getIt<RankingProdutosFaturamentoRepository>();

          final result = await runE2eAppResult(
            () => repository.load(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: RankingProdutosFaturamentoFilter(
                dataVendaInicio: periodStart,
                dataVendaFim: periodEnd,
                quantidadeProdutos: 5,
              ),
            ),
          );

          result.fold(
            (loadResult) => assertRankingLoadResult(
              loadResult,
              maxQuantidadeProdutos: 5,
            ),
            assertAcceptableFailure,
          );
        },
      );

      test(
        'use case executes the same query (stack path)',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP load_ranking_produtos_faturamento use_case e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final useCase = getIt<LoadRankingProdutosFaturamentoUseCase>();

          final result = await runE2eAppResult(
            () => useCase(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: RankingProdutosFaturamentoFilter(
                dataVendaInicio: periodStart,
                dataVendaFim: periodEnd,
                quantidadeProdutos: 10,
              ),
            ),
          );

          result.fold(
            (loadResult) => assertRankingLoadResult(
              loadResult,
              maxQuantidadeProdutos: 10,
            ),
            assertAcceptableFailure,
          );
        },
      );

      test(
        'load with codEmpresa and codFilial restricts to one branch when data exists',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP ranking_produtos_faturamento_repository_e2e (branch filter): '
              'missing ${missingKeys.join(', ')}.',
            );
            return;
          }

          final repository = getIt<RankingProdutosFaturamentoRepository>();

          final unfiltered = await runE2eAppResult(
            () => repository.load(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: RankingProdutosFaturamentoFilter(
                dataVendaInicio: periodStart,
                dataVendaFim: periodEnd,
                quantidadeProdutos: 5,
              ),
            ),
          );

          final sampleBranch = unfiltered.fold(
            (loadResult) {
              final first = loadResult.rows.firstOrNull;
              if (first == null) {
                return null;
              }
              return (codEmpresa: first.codEmpresa, codFilial: first.codFilial);
            },
            (_) => null,
          );

          if (sampleBranch == null) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP ranking_produtos_faturamento_repository_e2e (branch filter): '
              'no rows in unfiltered load.',
            );
            return;
          }

          final filtered = await runE2eAppResult(
            () => repository.load(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: RankingProdutosFaturamentoFilter(
                dataVendaInicio: periodStart,
                dataVendaFim: periodEnd,
                quantidadeProdutos: 5,
                codEmpresa: sampleBranch.codEmpresa,
                codFilial: sampleBranch.codFilial,
              ),
            ),
          );

          filtered.fold(
            (loadResult) => assertRankingLoadResult(
              loadResult,
              maxQuantidadeProdutos: 5,
              expectedCodEmpresa: sampleBranch.codEmpresa,
              expectedCodFilial: sampleBranch.codFilial,
            ),
            assertAcceptableFailure,
          );
        },
      );
    },
    tags: <String>['e2e'],
  );
}
