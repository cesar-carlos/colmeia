import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/overview/data/overview_batch_loader.dart';
import 'package:colmeia/features/overview/data/overview_user_rankings_override_policy.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  const labels = OverviewLoadLabels.englishFallback;

  test('counts payment rows with non-empty trimmed nomeUsuario', () {
    check(
      overviewPaymentMergedRowsWithNamedUsuarioCount(
        const <ResumoParcelaFormaPagamentoRow>[
          ResumoParcelaFormaPagamentoRow(
            codEmpresa: 1,
            codFilial: 1,
            nomeUsuario: '  Ana  ',
            anoDataVenda: 2026,
            mesDataVenda: 4,
            anoMesDataVenda: '2026/04',
            codFormaPagamento: 'PIX',
            descricaoFormaPagamento: 'Pix',
            qtdVendas: 1,
            valorParcela: 10,
          ),
          ResumoParcelaFormaPagamentoRow(
            codEmpresa: 1,
            codFilial: 1,
            nomeUsuario: '   ',
            anoDataVenda: 2026,
            mesDataVenda: 4,
            anoMesDataVenda: '2026/04',
            codFormaPagamento: 'PIX',
            descricaoFormaPagamento: 'Pix',
            qtdVendas: 1,
            valorParcela: 5,
          ),
        ],
      ),
    ).equals(1);
  });

  test(
    'across-agents override is null when per-user resumo succeeds with no rows',
    () {
      const report = AgentQueryExecutionReport<ResumoParcelaPorUsuarioRow>(
        queryKey: AgentQueryKey.resumoParcelaPorUsuario,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 1,
        plannedTargets: <AgentQueryTarget>[
          AgentQueryTarget(
            agentId: 'agent-a',
            displayName: 'Agent A',
            connectionStatus: AgentConnectionStatus.online,
            clientToken: 'tok',
            hubConnectedFromApprovedCatalogRow: true,
          ),
        ],
        missingClientTokenTargets: <AgentQueryTarget>[],
        participants: <AgentQueryExecutionParticipant<ResumoParcelaPorUsuarioRow>>[
          AgentQueryExecutionParticipant<ResumoParcelaPorUsuarioRow>(
            agentId: 'agent-a',
            displayName: 'Agent A',
            rows: <ResumoParcelaPorUsuarioRow>[],
            elapsedMs: 1,
          ),
        ],
        totalElapsedMs: 1,
      );
      final override = overviewUserRankingsOverrideFromAcrossAgentsResult(
        userPorResult:
            const Success<
              AgentQueryExecutionReport<ResumoParcelaPorUsuarioRow>,
              AppFailure
            >(report),
        paymentMergedRows: const <ResumoParcelaFormaPagamentoRow>[],
        userId: 'user-1',
        rowLabels: labels,
        operation: 'test',
      );
      check(override).isNull();
    },
  );

  test('across-agents override maps non-empty merged rows', () {
    const report = AgentQueryExecutionReport<ResumoParcelaPorUsuarioRow>(
      queryKey: AgentQueryKey.resumoParcelaPorUsuario,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      consideredApprovedAgentCount: 1,
      plannedTargets: <AgentQueryTarget>[
        AgentQueryTarget(
          agentId: 'agent-a',
          displayName: 'Agent A',
          connectionStatus: AgentConnectionStatus.online,
          clientToken: 'tok',
          hubConnectedFromApprovedCatalogRow: true,
        ),
      ],
      missingClientTokenTargets: <AgentQueryTarget>[],
      participants: <AgentQueryExecutionParticipant<ResumoParcelaPorUsuarioRow>>[
          AgentQueryExecutionParticipant<ResumoParcelaPorUsuarioRow>(
            agentId: 'agent-a',
            displayName: 'Agent A',
            rows: <ResumoParcelaPorUsuarioRow>[
              ResumoParcelaPorUsuarioRow(
                codEmpresa: 1,
                codFilial: 1,
                nomeUsuario: 'Caixa',
                qtdVendas: 2,
              valorParcela: 100,
            ),
          ],
          elapsedMs: 1,
        ),
      ],
      totalElapsedMs: 1,
    );
    final override = overviewUserRankingsOverrideFromAcrossAgentsResult(
      userPorResult:
          const Success<
            AgentQueryExecutionReport<ResumoParcelaPorUsuarioRow>,
            AppFailure
          >(report),
      paymentMergedRows: const <ResumoParcelaFormaPagamentoRow>[],
      userId: 'user-1',
      rowLabels: labels,
      operation: 'test',
    );
    check(override).isNotNull();
    check(override!.single.userName).equals('Caixa');
    check(override.single.totalSalesCount).equals(2);
    check(override.single.totalAmount).equals(100);
  });

  test('batch override is null when every target returns no user rows', () {
    const target = AgentQueryTarget(
      agentId: 'agent-a',
      displayName: 'Agent A',
      connectionStatus: AgentConnectionStatus.online,
      clientToken: 'tok',
      hubConnectedFromApprovedCatalogRow: true,
    );
    final override = overviewUserRankingsOverrideFromBatchTargetResults(
      batchResults: <OverviewBatchTargetResult>[
        const OverviewBatchTargetResult(
          target: target,
          elapsedMs: 1,
        ),
      ],
      paymentMergedRows: const <ResumoParcelaFormaPagamentoRow>[],
      userId: 'user-1',
      rowLabels: labels,
      operation: 'test',
    );
    check(override).isNull();
  });

  test('batch override maps merged rows from multiple targets', () {
    const targetA = AgentQueryTarget(
      agentId: 'agent-a',
      displayName: 'Agent A',
      connectionStatus: AgentConnectionStatus.online,
      clientToken: 'tok-a',
      hubConnectedFromApprovedCatalogRow: true,
    );
    const targetB = AgentQueryTarget(
      agentId: 'agent-b',
      displayName: 'Agent B',
      connectionStatus: AgentConnectionStatus.online,
      clientToken: 'tok-b',
      hubConnectedFromApprovedCatalogRow: true,
    );
    final override = overviewUserRankingsOverrideFromBatchTargetResults(
      batchResults: <OverviewBatchTargetResult>[
        const OverviewBatchTargetResult(
          target: targetA,
          elapsedMs: 1,
          userRankingRows: <ResumoParcelaPorUsuarioRow>[
            ResumoParcelaPorUsuarioRow(
              codEmpresa: 1,
              codFilial: 1,
              nomeUsuario: 'Ana',
              qtdVendas: 1,
              valorParcela: 50,
            ),
          ],
        ),
        const OverviewBatchTargetResult(
          target: targetB,
          elapsedMs: 2,
          userRankingRows: <ResumoParcelaPorUsuarioRow>[
            ResumoParcelaPorUsuarioRow(
              codEmpresa: 2,
              codFilial: 1,
              nomeUsuario: 'Bob',
              qtdVendas: 2,
              valorParcela: 80,
            ),
          ],
        ),
      ],
      paymentMergedRows: const <ResumoParcelaFormaPagamentoRow>[],
      userId: 'user-1',
      rowLabels: labels,
      operation: 'test',
    );
    check(override).isNotNull();
    check(override!.length).equals(2);
    final names = override.map((r) => r.userName).toSet();
    check(names.contains('Ana')).isTrue();
    check(names.contains('Bob')).isTrue();
  });

  test('across-agents override is null when per-user resumo call fails', () {
    final override = overviewUserRankingsOverrideFromAcrossAgentsResult(
      userPorResult: const Failure<AgentQueryExecutionReport<ResumoParcelaPorUsuarioRow>, AppFailure>(
        ValidationFailure(message: 'bridge failed'),
      ),
      paymentMergedRows: const <ResumoParcelaFormaPagamentoRow>[],
      userId: 'user-1',
      rowLabels: labels,
      operation: 'test',
    );
    check(override).isNull();
  });

  test(
    'batch override still maps when some targets fail user ranking',
    () {
      const targetA = AgentQueryTarget(
        agentId: 'agent-a',
        displayName: 'Agent A',
        connectionStatus: AgentConnectionStatus.online,
        clientToken: 'tok-a',
        hubConnectedFromApprovedCatalogRow: true,
      );
      const targetB = AgentQueryTarget(
        agentId: 'agent-b',
        displayName: 'Agent B',
        connectionStatus: AgentConnectionStatus.online,
        clientToken: 'tok-b',
        hubConnectedFromApprovedCatalogRow: true,
      );
      final override = overviewUserRankingsOverrideFromBatchTargetResults(
        batchResults: <OverviewBatchTargetResult>[
          const OverviewBatchTargetResult(
            target: targetA,
            elapsedMs: 1,
            userRankingFailure: ValidationFailure(message: 'timeout'),
          ),
          const OverviewBatchTargetResult(
            target: targetB,
            elapsedMs: 2,
            userRankingRows: <ResumoParcelaPorUsuarioRow>[
              ResumoParcelaPorUsuarioRow(
                codEmpresa: 2,
                codFilial: 1,
                nomeUsuario: 'Bob',
                qtdVendas: 1,
                valorParcela: 99,
              ),
            ],
          ),
        ],
        paymentMergedRows: const <ResumoParcelaFormaPagamentoRow>[],
        userId: 'user-1',
        rowLabels: labels,
        operation: 'test',
      );
      check(override).isNotNull();
      check(override!.single.userName).equals('Bob');
      check(override.single.totalAmount).equals(99);
    },
  );
}
