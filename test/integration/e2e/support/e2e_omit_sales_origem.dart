import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';

/// Drops `pv.Origem` / `Origem` equality filters before E2E SQL hits the bridge.
///
/// The current E2E database has no `FrenteLoja` sales. Production filters keep
/// that default; only this harness removes the predicate and the `:origem` bind.
final RegExp e2eSalesOrigemPredicate = RegExp(
  r'''\s+AND\s+(?:[A-Za-z_][A-Za-z0-9_]*\.)?Origem\s*=\s*(?::origem\b|'[^']*')''',
);

String omitE2eSalesOrigemSql(String sql) {
  return sql.replaceAll(e2eSalesOrigemPredicate, '');
}

Map<String, Object?> omitE2eSalesOrigemParams(
  String sql,
  Map<String, Object?> namedParams,
) {
  if (sql.contains(':origem') || !namedParams.containsKey('origem')) {
    return namedParams;
  }
  return Map<String, Object?>.of(namedParams)..remove('origem');
}

Future<void> installE2eOmitSalesOrigemRepository() async {
  final inner = getIt<AgentQueriesRepository>();
  await getIt.unregister<AgentQueriesRepository>();
  getIt.registerSingleton<AgentQueriesRepository>(
    E2eOmitSalesOrigemAgentQueriesRepository(inner),
  );
}

final class E2eOmitSalesOrigemAgentQueriesRepository
    implements AgentQueriesRepository {
  E2eOmitSalesOrigemAgentQueriesRepository(this._delegate);

  final AgentQueriesRepository _delegate;

  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    final sql = omitE2eSalesOrigemSql(request.sql);
    return _delegate.executeSql(
      request.copyWith(
        sql: sql,
        namedParams: omitE2eSalesOrigemParams(sql, request.namedParams),
      ),
      cancelScope: cancelScope,
    );
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    final commands = request.commands
        .map((command) {
          final sql = omitE2eSalesOrigemSql(command.sql);
          return AgentSqlExecuteBatchCommand(
            sql: sql,
            namedParams: omitE2eSalesOrigemParams(sql, command.namedParams),
            executionOrder: command.executionOrder,
          );
        })
        .toList(growable: false);
    return _delegate.executeSqlBatch(
      request.copyWith(commands: commands),
      cancelScope: cancelScope,
    );
  }
}
