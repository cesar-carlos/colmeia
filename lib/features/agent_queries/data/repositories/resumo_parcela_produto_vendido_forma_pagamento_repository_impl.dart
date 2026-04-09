import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcela_produto_vendido_forma_pagamento_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_produto_vendido_forma_pagamento_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_produto_vendido_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_produto_vendido_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_produto_vendido_forma_pagamento_repository.dart';
import 'package:intl/intl.dart';
import 'package:result_dart/result_dart.dart';

class ResumoParcelaProdutoVendidoFormaPagamentoRepositoryImpl
    implements ResumoParcelaProdutoVendidoFormaPagamentoRepository {
  ResumoParcelaProdutoVendidoFormaPagamentoRepositoryImpl(
    this._agentQueriesRepository,
  );

  static final DateFormat _sqlDateFormat = DateFormat('yyyy-MM-dd');
  static const int _defaultBridgeTimeoutMs = 120000;

  final AgentQueriesRepository _agentQueriesRepository;

  @override
  Future<AppResult<List<ResumoParcelaProdutoVendidoFormaPagamentoRow>>> load({
    required String agentId,
    required ResumoParcelaProdutoVendidoFormaPagamentoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
  }) async {
    final validationError = filter.validationError();
    if (validationError != null) {
      return Failure<
        List<ResumoParcelaProdutoVendidoFormaPagamentoRow>,
        AppFailure
      >(
        ValidationFailure(
          message: validationError,
          userMessage: 'Os filtros da consulta sao invalidos.',
          context: <String, Object?>{
            'operation': 'loadResumoParcelaProdutoVendidoFormaPagamento',
            'agentId': agentId.trim(),
          },
        ),
      );
    }

    final request = AgentSqlExecuteRequest(
      agentId: agentId,
      sql: ResumoParcelaProdutoVendidoFormaPagamentoSql.query,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs ?? _defaultBridgeTimeoutMs,
      namedParams: <String, Object?>{
        'dataVendaInicio': _sqlDateFormat.format(filter.dataVendaInicio),
        'dataVendaFim': _sqlDateFormat.format(filter.dataVendaFim),
        'origem': filter.trimmedOrigem,
        'geraFinanceiro': filter.trimmedGeraFinanceiro,
        'preVenda': filter.trimmedPreVenda,
      },
      executeOptions: const AgentSqlExecuteOptions(
        executionMode: AgentSqlExecutionMode.preserve,
      ),
    );

    final result = await _agentQueriesRepository.executeSql(request);
    return result.fold(
      (executionResult) {
        try {
          final rows = executionResult.rows
              .map(
                (row) =>
                    ResumoParcelaProdutoVendidoFormaPagamentoRowModel.fromMap(
                      row,
                    ).toEntity(),
              )
              .toList(growable: false);
          return Success<
            List<ResumoParcelaProdutoVendidoFormaPagamentoRow>,
            AppFailure
          >(
            rows,
          );
        } on FormatException catch (error, stackTrace) {
          AppLogger.error(
            'Unexpected row shape for '
            'ResumoParcelaProdutoVendidoFormaPagamento',
            context: <String, Object?>{
              'operation': 'loadResumoParcelaProdutoVendidoFormaPagamento',
              'agentId': agentId.trim(),
            },
            error: error,
            stackTrace: stackTrace,
          );
          return Failure<
            List<ResumoParcelaProdutoVendidoFormaPagamentoRow>,
            AppFailure
          >(
            UnknownFailure(
              message: error.message,
              userMessage:
                  'Resposta do agente estava em formato inesperado. '
                  'Tente novamente.',
              cause: error,
              stackTrace: stackTrace,
              context: <String, Object?>{
                'operation': 'loadResumoParcelaProdutoVendidoFormaPagamento',
                'agentId': agentId.trim(),
              },
            ),
          );
        }
      },
      Failure<List<ResumoParcelaProdutoVendidoFormaPagamentoRow>, AppFailure>
          .new,
    );
  }
}
