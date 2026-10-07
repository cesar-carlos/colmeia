import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/repositories/progressive_report_loader.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:result_dart/result_dart.dart';

class PagedReportProgressLoader<Page extends Object, Row> {
  const PagedReportProgressLoader();

  Stream<AppResult<AgentQueryProgress<Row>>> load({
    required Future<AppResult<Page>> Function(int, AgentQueriesCancelScope)
    loadPage,
    required List<Row> Function(Page) items,
    required int Function(Page) totalCount,
    required Object Function(Row) rowKey,
    required int pageSize,
    required int maxRows,
    AgentQueriesCancelScope? parent,
    bool emitPartialResults = true,
  }) => ProgressiveReportLoader<Row>().loadBatches(
    parent: parent,
    execute: (scope, publish) async {
      final rows = <Row>[];
      final keys = <Object>{};
      int? expectedTotal;
      for (var page = 1; ; page++) {
        if (scope.isCancelled) {
          return const Failure(OperationCancelledFailure());
        }
        final result = await loadPage(page, scope);
        if (result.isError()) return Failure(result.exceptionOrNull()!);
        if (scope.isCancelled) {
          return const Failure(OperationCancelledFailure());
        }
        final value = result.getOrThrow();
        final batch = items(value);
        final total = totalCount(value);
        expectedTotal ??= total;
        if (total < 0 ||
            total != expectedTotal ||
            batch.length > pageSize ||
            rows.length + batch.length > total) {
          return const Failure(
            UnknownFailure(
              message: 'Progressive page totals changed or rows were truncated',
              context: {
                AgentSqlRpcFailureUiKey.field:
                    AgentSqlRpcFailureUiKey.unexpectedAgentResponse,
              },
            ),
          );
        }
        if (maxRows > 0 && total > maxRows) {
          return const Failure(
            ValidationFailure(
              message: 'Progressive report row limit exceeded',
              context: {
                AgentSqlRpcFailureUiKey.field:
                    AgentSqlRpcFailureUiKey.resultTooLarge,
              },
            ),
          );
        }
        if (batch.any((row) => !keys.add(rowKey(row)))) {
          return const Failure(
            UnknownFailure(
              message: 'Progressive pages contain duplicate row identities',
              context: {
                AgentSqlRpcFailureUiKey.field:
                    AgentSqlRpcFailureUiKey.unexpectedAgentResponse,
              },
            ),
          );
        }
        rows.addAll(batch);
        if (rows.length == total) return Success(rows);
        if (batch.length != pageSize) {
          return const Failure(
            UnknownFailure(
              message: 'Progressive report ended before its declared total',
              context: {
                AgentSqlRpcFailureUiKey.field:
                    AgentSqlRpcFailureUiKey.unexpectedAgentResponse,
              },
            ),
          );
        }
        if (emitPartialResults) {
          publish(batch);
        }
      }
    },
  );
}
