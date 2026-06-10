import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/queries/grupo_produto_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/marca_produto_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/grupo_marca_produto_options_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late GrupoMarcaProdutoOptionsRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteBatchRequest(
        agentId: 'fallback-agent',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
      ),
    );
  });

  setUp(() {
    agentQueriesRepository = _MockAgentQueriesRepository();
    repository = GrupoMarcaProdutoOptionsRepositoryImpl(agentQueriesRepository);
  });

  test(
    'loadGrupoAndMarcaOptions sends batch with grupo and marca SQL',
    () async {
      when(
        () => agentQueriesRepository.executeSqlBatch(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlBatchExecutionResult, AppFailure>(
          AgentSqlBatchExecutionResult(
            items: <AgentSqlBatchExecutionItem>[
              AgentSqlBatchExecutionItem(
                index: 0,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
              AgentSqlBatchExecutionItem(
                index: 1,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
            ],
            totalCommands: 2,
            successfulCommands: 2,
            failedCommands: 0,
          ),
        ),
      );

      await repository.loadGrupoAndMarcaOptions(
        userId: 'user-1',
        agentId: 'agent-1',
        pageSize: 200,
      );

      final captured =
          verify(
                () => agentQueriesRepository.executeSqlBatch(captureAny()),
              ).captured.single
              as AgentSqlExecuteBatchRequest;
      check(captured.commands).length.equals(2);
      check(captured.commands[0].sql).equals(GrupoProdutoOptionsSql.pagedQuery);
      check(captured.commands[1].sql).equals(MarcaProdutoOptionsSql.pagedQuery);
      check(captured.commands[0].namedParams['startRow']).equals(1);
      check(captured.commands[0].namedParams['endRow']).equals(200);
      check(captured.useRelay).isTrue();
    },
  );

  test(
    'loadGrupoAndMarcaOptions forwards cancelScope to executeSqlBatch',
    () async {
      when(
        () => agentQueriesRepository.executeSqlBatch(
          any(),
          cancelScope: any(named: 'cancelScope'),
        ),
      ).thenAnswer(
        (_) async => const Success<AgentSqlBatchExecutionResult, AppFailure>(
          AgentSqlBatchExecutionResult(
            items: <AgentSqlBatchExecutionItem>[
              AgentSqlBatchExecutionItem(
                index: 0,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
              AgentSqlBatchExecutionItem(
                index: 1,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
            ],
            totalCommands: 2,
            successfulCommands: 2,
            failedCommands: 0,
          ),
        ),
      );

      final cancelScope = AgentQueriesCancelScope();
      await repository.loadGrupoAndMarcaOptions(
        userId: 'user-1',
        agentId: 'agent-1',
        cancelScope: cancelScope,
      );

      final capturedCancelScope =
          verify(
                () => agentQueriesRepository.executeSqlBatch(
                  any(),
                  cancelScope: captureAny(named: 'cancelScope'),
                ),
              ).captured.single
              as AgentQueriesCancelScope;
      check(identical(capturedCancelScope, cancelScope)).isTrue();
    },
  );

  test('returns validation failure when page is invalid', () async {
    final result = await repository.loadGrupoAndMarcaOptions(
      userId: 'user-1',
      agentId: 'agent-1',
      page: 0,
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSqlBatch(any()));
  });

  test('returns validation failure when pageSize exceeds max', () async {
    final result = await repository.loadGrupoAndMarcaOptions(
      userId: 'user-1',
      agentId: 'agent-1',
      pageSize: 501,
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSqlBatch(any()));
  });

  test('maps valid batch rows to grupo and marca entities', () async {
    when(
      () => agentQueriesRepository.executeSqlBatch(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlBatchExecutionResult, AppFailure>(
        AgentSqlBatchExecutionResult(
          items: <AgentSqlBatchExecutionItem>[
            AgentSqlBatchExecutionItem(
              index: 0,
              ok: true,
              rows: <Map<String, dynamic>>[
                <String, dynamic>{
                  'CodGrupoProduto': 14,
                  'NomeGrupoProduto': 'SUSPENSAO',
                },
              ],
              rowCount: 1,
            ),
            AgentSqlBatchExecutionItem(
              index: 1,
              ok: true,
              rows: <Map<String, dynamic>>[
                <String, dynamic>{
                  'CodMarca': 490,
                  'NomeMarca': 'SMART FOX',
                },
              ],
              rowCount: 1,
            ),
          ],
          totalCommands: 2,
          successfulCommands: 2,
          failedCommands: 0,
        ),
      ),
    );

    final result = await repository.loadGrupoAndMarcaOptions(
      userId: 'user-1',
      agentId: 'agent-1',
    );

    check(result.isSuccess()).isTrue();
    final batch = result.getOrThrow();
    check(batch.grupoOptions.single.codGrupoProduto).equals(14);
    check(batch.marcaOptions.single.codMarca).equals(490);
  });

  test('returns RpcFailure when grupo batch item is missing', () async {
    when(
      () => agentQueriesRepository.executeSqlBatch(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlBatchExecutionResult, AppFailure>(
        AgentSqlBatchExecutionResult(
          items: <AgentSqlBatchExecutionItem>[
            AgentSqlBatchExecutionItem(
              index: 1,
              ok: true,
              rows: <Map<String, dynamic>>[],
              rowCount: 0,
            ),
          ],
          totalCommands: 2,
          successfulCommands: 1,
          failedCommands: 0,
        ),
      ),
    );

    final result = await repository.loadGrupoAndMarcaOptions(
      userId: 'user-1',
      agentId: 'agent-1',
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<RpcFailure>();
  });
}
