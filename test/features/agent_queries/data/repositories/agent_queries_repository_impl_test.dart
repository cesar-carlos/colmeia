import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAgentQueriesRemoteDataSource extends Mock
    implements AgentQueriesRemoteDataSource {}

void main() {
  late _MockAgentQueriesRemoteDataSource remoteDataSource;
  late AgentQueriesRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(
        agentId: 'fallback-agent',
        sql: 'SELECT 1',
      ),
    );
  });

  setUp(() {
    remoteDataSource = _MockAgentQueriesRemoteDataSource();
    repository = AgentQueriesRepositoryImpl(remoteDataSource);
  });

  test(
    'should return validation failure when preserve mode is combined '
    'with pagination',
    () async {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT * FROM table ORDER BY id',
        pagination: AgentSqlPagePagination(page: 1, pageSize: 20),
        executeOptions: AgentSqlExecuteOptions(
          executionMode: AgentSqlExecutionMode.preserve,
        ),
      );

      final result = await repository.executeSql(request);

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<ValidationFailure>();
      check(result.exceptionOrNull()?.displayMessage).equals(
        'Os parametros da consulta do agente sao invalidos.',
      );
      verifyNever(() => remoteDataSource.postSqlExecute(any()));
    },
  );

  test(
    'should return validation failure when namedParams exceed bridge limit',
    () async {
      final request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        namedParams: <String, Object?>{
          for (var i = 0;
              i < AgentSqlExecuteRequest.bridgeMaxNamedParameterCount + 1;
              i++)
            'p$i': i,
        },
      );

      final result = await repository.executeSql(request);

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<ValidationFailure>();
      verifyNever(() => remoteDataSource.postSqlExecute(any()));
    },
  );

  test(
    'should preserve rpc error details when bridge returns item error',
    () async {
      when(
        () => remoteDataSource.postSqlExecute(any()),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'response': <String, dynamic>{
            'success': false,
            'item': <String, dynamic>{
              'success': false,
              'error': <String, dynamic>{
                'code': -32008,
                'message': 'SQL timeout',
                'data': <String, dynamic>{
                  'reason': 'timeout',
                  'category': 'transport',
                  'retryable': true,
                  'user_message': 'Tempo esgotado para consultar o agente.',
                  'technical_message': 'bridge timeout waiting rpc:response',
                  'correlation_id': 'corr-123',
                  'timestamp': '2026-04-08T21:15:00Z',
                },
              },
            },
          },
        },
      );

      final result = await repository.executeSql(
        const AgentSqlExecuteRequest(
          agentId: 'agent-1',
          sql: 'SELECT 1',
        ),
      );

      check(result.isError()).isTrue();
      final failure = result.exceptionOrNull();
      check(failure).isA<RpcFailure>();
      final rpcFailure = failure! as RpcFailure;
      check(rpcFailure.displayMessage).equals(
        'The agent took too long to respond. Please try again.',
      );
      check(rpcFailure.isTransient).isTrue();
      check(rpcFailure.rpcCode).equals(-32008);
      check(rpcFailure.reason).equals('timeout');
      check(rpcFailure.category).equals('transport');
      check(
        rpcFailure.context[AgentSqlRpcFailureUiKey.field],
      ).equals(AgentSqlRpcFailureUiKey.transportTimeout);
      check(rpcFailure.technicalMessage).equals(
        'bridge timeout waiting rpc:response',
      );
      check(rpcFailure.correlationId).equals('corr-123');
      check(
        rpcFailure.timestamp,
      ).equals(DateTime.parse('2026-04-08T21:15:00Z'));
    },
  );

  test(
    'should classify auth RPC errors and prefer bridge user_message',
    () async {
      when(
        () => remoteDataSource.postSqlExecute(any()),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'response': <String, dynamic>{
            'success': false,
            'item': <String, dynamic>{
              'success': false,
              'error': <String, dynamic>{
                'code': -32002,
                'message': 'Not authorized',
                'data': <String, dynamic>{
                  'reason': 'unauthorized',
                  'category': 'auth',
                  'retryable': false,
                  'user_message':
                      'Seu cliente nao possui permissao para consultar.',
                  'correlation_id': 'c1',
                },
              },
            },
          },
        },
      );

      final result = await repository.executeSql(
        const AgentSqlExecuteRequest(
          agentId: 'agent-1',
          sql: 'SELECT 1',
        ),
      );

      check(result.isError()).isTrue();
      final rpcFailure = result.exceptionOrNull()! as RpcFailure;
      check(rpcFailure.displayMessage).equals(
        'Seu cliente nao possui permissao para consultar.',
      );
      check(
        rpcFailure.context[AgentSqlRpcFailureUiKey.field],
      ).equals(AgentSqlRpcFailureUiKey.permissionDenied);
      check(
        rpcFailure.context[AgentSqlRpcFailureUiKey
            .preferBridgeUserMessageField],
      ).equals(true);
    },
  );

  test('should map invalid params -32602 to query validation UI key', () async {
    when(
      () => remoteDataSource.postSqlExecute(any()),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'response': <String, dynamic>{
          'success': false,
          'item': <String, dynamic>{
            'success': false,
            'error': <String, dynamic>{
              'code': -32602,
              'message': 'Pagination requires ORDER BY',
              'data': <String, dynamic>{
                'reason': 'invalid_params',
                'category': 'validation',
                'retryable': false,
              },
            },
          },
        },
      },
    );

    final result = await repository.executeSql(
      const AgentSqlExecuteRequest(agentId: 'a', sql: 'SELECT 1'),
    );

    final rpcFailure = result.exceptionOrNull()! as RpcFailure;
    check(rpcFailure.displayMessage).equals('Pagination requires ORDER BY');
    check(
      rpcFailure.context[AgentSqlRpcFailureUiKey.field],
    ).equals(AgentSqlRpcFailureUiKey.sqlValidationFailed);
  });

  test('should map missing client token to authentication UI key', () async {
    when(
      () => remoteDataSource.postSqlExecute(any()),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'response': <String, dynamic>{
          'success': false,
          'item': <String, dynamic>{
            'success': false,
            'error': <String, dynamic>{
              'code': -32001,
              'message': 'Authentication failed',
              'data': <String, dynamic>{
                'reason': 'missing_client_token',
                'category': 'auth',
                'retryable': false,
              },
            },
          },
        },
      },
    );

    final result = await repository.executeSql(
      const AgentSqlExecuteRequest(agentId: 'a', sql: 'SELECT 1'),
    );

    final rpcFailure = result.exceptionOrNull()! as RpcFailure;
    check(
      rpcFailure.context[AgentSqlRpcFailureUiKey.field],
    ).equals(AgentSqlRpcFailureUiKey.authenticationFailed);
  });

  test('should map rate limited transport errors', () async {
    when(
      () => remoteDataSource.postSqlExecute(any()),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'response': <String, dynamic>{
          'success': false,
          'item': <String, dynamic>{
            'success': false,
            'error': <String, dynamic>{
              'code': -32013,
              'message': 'Rate limited',
              'data': <String, dynamic>{
                'reason': 'rate_limited',
                'category': 'transport',
                'retryable': false,
              },
            },
          },
        },
      },
    );

    final result = await repository.executeSql(
      const AgentSqlExecuteRequest(agentId: 'a', sql: 'SELECT 1'),
    );

    final rpcFailure = result.exceptionOrNull()! as RpcFailure;
    check(
      rpcFailure.context[AgentSqlRpcFailureUiKey.field],
    ).equals(AgentSqlRpcFailureUiKey.rateLimited);
  });

  test('should map SQL validation catalog code -32101', () async {
    when(
      () => remoteDataSource.postSqlExecute(any()),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'response': <String, dynamic>{
          'success': false,
          'item': <String, dynamic>{
            'success': false,
            'error': <String, dynamic>{
              'code': -32101,
              'message': 'bad sql',
              'data': <String, dynamic>{
                'reason': 'validation',
                'retryable': false,
              },
            },
          },
        },
      },
    );

    final result = await repository.executeSql(
      const AgentSqlExecuteRequest(agentId: 'a', sql: 'SELECT 1'),
    );

    final rpcFailure = result.exceptionOrNull()! as RpcFailure;
    check(rpcFailure.displayMessage).equals('bad sql');
    check(
      rpcFailure.context[AgentSqlRpcFailureUiKey.field],
    ).equals(AgentSqlRpcFailureUiKey.sqlValidationFailed);
    check(
      rpcFailure.context[AgentSqlRpcFailureUiKey.errorDataField],
    ).isNotNull();
  });

  test('should map SQL query timeout -32107 as retryable', () async {
    when(
      () => remoteDataSource.postSqlExecute(any()),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'response': <String, dynamic>{
          'success': false,
          'item': <String, dynamic>{
            'success': false,
            'error': <String, dynamic>{
              'code': -32107,
              'message': 'timeout',
              'data': <String, dynamic>{
                'reason': 'timeout',
                'retryable': true,
              },
            },
          },
        },
      },
    );

    final result = await repository.executeSql(
      const AgentSqlExecuteRequest(agentId: 'a', sql: 'SELECT 1'),
    );

    final rpcFailure = result.exceptionOrNull()! as RpcFailure;
    check(rpcFailure.isTransient).isTrue();
    check(
      rpcFailure.context[AgentSqlRpcFailureUiKey.field],
    ).equals(AgentSqlRpcFailureUiKey.queryTimeout);
  });

  test(
    'should pass through unclassified bridge user_message without ui key',
    () async {
      when(
        () => remoteDataSource.postSqlExecute(any()),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'response': <String, dynamic>{
            'success': false,
            'item': <String, dynamic>{
              'success': false,
              'error': <String, dynamic>{
                'code': -31999,
                'message': 'Custom vendor message',
                'data': <String, dynamic>{
                  'retryable': false,
                },
              },
            },
          },
        },
      );

      final result = await repository.executeSql(
        const AgentSqlExecuteRequest(agentId: 'a', sql: 'SELECT 1'),
      );

      final rpcFailure = result.exceptionOrNull()! as RpcFailure;
      check(rpcFailure.displayMessage).equals('Custom vendor message');
      check(rpcFailure.context[AgentSqlRpcFailureUiKey.field]).isNull();
    },
  );
}
