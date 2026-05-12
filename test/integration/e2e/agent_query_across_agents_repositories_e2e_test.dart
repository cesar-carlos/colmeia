@Tags(['e2e'])
library;

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart'
    show AppFailure, SessionFailure;
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_diario_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_anual_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_usuario_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_forma_pagamento_por_mes_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'Across-agent repository coverage',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test('load payment-method resumo variants through mergeAll', () async {
        if (_skipWhenMissingKeys('agent_query_across_payment_methods')) {
          return;
        }

        final period = _recentPeriod();

        final formaPagamento =
            getIt<LoadResumoParcelaFormaPagamentoAcrossAgentsUseCase>();
        _expectReport(
          await runE2eAppResult(
            () => formaPagamento(
              userId: 'e2e-agent-query-user',
              filter: ResumoParcelaFormaPagamentoFilter(
                dataVendaInicio: period.start,
                dataVendaFim: period.end,
              ),
              bridgeTimeoutMs: 300000,
            ),
          ),
          (row) {
            expect(row.codEmpresa, greaterThan(0));
            expect(row.codFilial, greaterThanOrEqualTo(0));
            expect(row.nomeUsuario, isNotEmpty);
            expect(row.anoDataVenda, greaterThan(1900));
            expect(row.mesDataVenda, inInclusiveRange(1, 12));
            expect(row.codFormaPagamento, isNotEmpty);
            expect(row.descricaoFormaPagamento, isNotEmpty);
            expect(row.qtdVendas, greaterThanOrEqualTo(0));
            expect(row.valorParcela, isNonNegative);
          },
        );

        final formaPagamentoDiario =
            getIt<LoadResumoParcelaFormaPagamentoDiarioAcrossAgentsUseCase>();
        _expectReport(
          await runE2eAppResult(
            () => formaPagamentoDiario(
              userId: 'e2e-agent-query-user',
              filter: ResumoParcelaFormaPagamentoDiarioFilter(
                dataVendaInicio: period.start,
                dataVendaFim: period.end,
              ),
              bridgeTimeoutMs: 300000,
            ),
          ),
          (row) {
            expect(row.codEmpresa, greaterThan(0));
            expect(row.codFilial, greaterThanOrEqualTo(0));
            expect(row.codProdutoVendido, greaterThan(0));
            expect(row.origem, isNotEmpty);
            expect(row.anoMesDataVenda, isNotEmpty);
            expect(row.nomeUsuario, isNotEmpty);
            expect(row.qtdVendas, greaterThanOrEqualTo(0));
            expect(row.valorTotalVenda, isNonNegative);
          },
        );

        final formaPagamentoPorMes =
            getIt<LoadResumoParcelasFormaPagamentoPorMesAcrossAgentsUseCase>();
        _expectReport(
          await runE2eAppResult(
            () => formaPagamentoPorMes(
              userId: 'e2e-agent-query-user',
              filter: ResumoParcelasFormaPagamentoPorMesFilter(
                dataVendaInicio: period.start,
                dataVendaFim: period.end,
              ),
              bridgeTimeoutMs: 300000,
            ),
          ),
          (row) {
            expect(row.codEmpresa, greaterThan(0));
            expect(row.codFilial, greaterThanOrEqualTo(0));
            expect(row.nomeUsuario, isNotEmpty);
            expect(row.anoMesDataVenda, matches(RegExp(r'^\d{4}/\d{1,2}$')));
            expect(row.codFormaPagamento, isNotEmpty);
            expect(row.descricaoFormaPagamento, isNotEmpty);
            expect(row.qtdVendas, greaterThanOrEqualTo(0));
            expect(row.valorParcela, isNonNegative);
          },
        );
      });

      test(
        'load annual, weekday-user, daily total, and seller reports',
        () async {
          if (_skipWhenMissingKeys('agent_query_across_sales_reports')) {
            return;
          }

          final period = _recentPeriod();
          final yearStart = DateTime(period.end.year);

          final anual = getIt<LoadResumoParcelasAnualAcrossAgentsUseCase>();
          _expectReport(
            await runE2eAppResult(
              () => anual(
                userId: 'e2e-agent-query-user',
                filter: ResumoParcelasAnualFilter(
                  dataVendaInicio: yearStart,
                  dataVendaFim: period.end,
                ),
                bridgeTimeoutMs: 300000,
              ),
            ),
            (row) {
              expect(row.codEmpresa, greaterThan(0));
              expect(row.codFilial, greaterThanOrEqualTo(0));
              expect(row.anoDataVenda, greaterThan(1900));
              expect(row.qtdVendas, greaterThanOrEqualTo(0));
              expect(row.valorTotalVenda, isNonNegative);
            },
          );

          final diaSemanaUsuario =
              getIt<LoadResumoParcelasDiaSemanaUsuarioAcrossAgentsUseCase>();
          _expectReport(
            await runE2eAppResult(
              () => diaSemanaUsuario(
                userId: 'e2e-agent-query-user',
                filter: ResumoParcelasDiaSemanaFilter(
                  dataVendaInicio: period.start,
                  dataVendaFim: period.end,
                ),
                bridgeTimeoutMs: 300000,
              ),
            ),
            (row) {
              expect(row.codEmpresa, greaterThan(0));
              expect(row.codFilial, greaterThanOrEqualTo(0));
              expect(row.nomeUsuario, isNotEmpty);
              expect(row.diaSemanaNumero, inInclusiveRange(1, 7));
              expect(row.diaSemana, isNotEmpty);
              expect(row.qtdVendas, greaterThanOrEqualTo(0));
              expect(row.valorParcela, isNonNegative);
            },
          );

          final totalDiario =
              getIt<LoadResumoTotalDiarioVendasAcrossAgentsUseCase>();
          _expectReport(
            await runE2eAppResult(
              () => totalDiario(
                userId: 'e2e-agent-query-user',
                filter: ResumoTotalDiarioVendasFilter(
                  dataVendaInicio: period.start,
                  dataVendaFim: period.end,
                ),
                bridgeTimeoutMs: 300000,
              ),
            ),
            (row) {
              expect(row.codEmpresa, greaterThan(0));
              expect(row.codFilial, greaterThanOrEqualTo(0));
              expect(row.qtdVendas, greaterThanOrEqualTo(0));
              expect(row.valorTotalDiarioVenda, isNonNegative);
            },
          );

          final vendedor =
              getIt<LoadResumoVendasDiariasPorVendedorAcrossAgentsUseCase>();
          _expectReport(
            await runE2eAppResult(
              () => vendedor(
                userId: 'e2e-agent-query-user',
                filter: ResumoVendasDiariasPorVendedorFilter(
                  dataVendaInicio: period.start,
                  dataVendaFim: period.end,
                ),
                bridgeTimeoutMs: 300000,
              ),
            ),
            (row) {
              expect(row.codEmpresa, greaterThan(0));
              expect(row.codFilial, greaterThanOrEqualTo(0));
              expect(row.anoMesDataVenda, isNotEmpty);
              expect(row.qtdVendas, greaterThanOrEqualTo(0));
              expect(row.valorTotalVenda, isNonNegative);
              final codVendedor = row.codVendedor;
              if (codVendedor != null) {
                expect(codVendedor, greaterThan(0));
              }
            },
          );
        },
      );

      test(
        'load seller filter options through the across-agent repository',
        () async {
          if (_skipWhenMissingKeys('agent_query_across_filter_options')) {
            return;
          }

          final period = _recentPeriod();

          final vendedorOptions =
              getIt<
                LoadResumoVendasDiariasPorVendedorVendedorOptionsAcrossAgentsUseCase
              >();
          _expectList(
            await runE2eAppResult(
              () => vendedorOptions(
                userId: 'e2e-agent-query-user',
                dataVendaInicio: period.start,
                dataVendaFim: period.end,
                limit: 5,
                bridgeTimeoutMs: 300000,
              ),
            ),
            (option) {
              expect(option.codVendedor, greaterThan(0));
              expect(option.nomeVendedor, isNotEmpty);
            },
          );

          final bairroOptions =
              getIt<
                LoadResumoVendasDiariasPorVendedorBairroOptionsAcrossAgentsUseCase
              >();
          _expectList(
            await runE2eAppResult(
              () => bairroOptions(
                userId: 'e2e-agent-query-user',
                dataVendaInicio: period.start,
                dataVendaFim: period.end,
                limit: 5,
                bridgeTimeoutMs: 300000,
              ),
            ),
            (option) => expect(option.value, isNotEmpty),
          );

          final municipioOptions =
              getIt<
                LoadResumoVendasDiariasPorVendedorMunicipioOptionsAcrossAgentsUseCase
              >();
          _expectList(
            await runE2eAppResult(
              () => municipioOptions(
                userId: 'e2e-agent-query-user',
                dataVendaInicio: period.start,
                dataVendaFim: period.end,
                limit: 5,
                bridgeTimeoutMs: 300000,
              ),
            ),
            (option) => expect(option.value, isNotEmpty),
          );
        },
      );
    },
    tags: <String>['e2e'],
  );
}

bool _skipWhenMissingKeys(String testName) {
  final missingKeys = missingE2eRepositoryKeys();
  if (missingKeys.isEmpty) {
    return false;
  }
  // E2E skip hint; `print` is intentional for local diagnostics.
  // ignore: avoid_print
  print(
    'SKIP $testName: missing ${missingKeys.join(', ')}. '
    'Set them in assets/env/local.env, process env, or --dart-define.',
  );
  return true;
}

({DateTime start, DateTime end}) _recentPeriod() {
  final today = DateTime.now();
  final end = DateTime(today.year, today.month, today.day);
  final start = end.subtract(const Duration(days: 14));
  return (start: start, end: end);
}

void _expectReport<Row>(
  AppResult<AgentQueryExecutionReport<Row>> result,
  void Function(Row row) verifyRow,
) {
  result.fold(
    (report) => report.mergedRows.forEach(verifyRow),
    _expectAcceptableFailure,
  );
}

void _expectList<T>(
  AppResult<List<T>> result,
  void Function(T item) verifyItem,
) {
  result.fold(
    (items) => items.forEach(verifyItem),
    _expectAcceptableFailure,
  );
}

void _expectAcceptableFailure(AppFailure failure) {
  expect(
    failure,
    isNot(isA<SessionFailure>()),
    reason: 'Unexpected HTTP 401 after client login; check E2E_* values.',
  );
  expect(
    isAcceptableE2eAgentSqlRepositoryFailure(failure),
    isTrue,
    reason:
        'Across-agents e2e should return rows, invalid_policy / '
        'missing_permission RPC, transient transport, queue saturation, '
        'or transient bridge HTTP 5xx.',
  );
}
