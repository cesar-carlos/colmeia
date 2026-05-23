import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_http_receive_timeout.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late ApiAgentQueriesRemoteDataSource dataSource;

  setUp(() {
    dio = _MockDio();
    dataSource = ApiAgentQueriesRemoteDataSource(dio: dio);
  });

  test(
    'should build normalized bridge payload when request has options',
    () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/agents/commands'),
          data: const <String, dynamic>{},
        ),
      );

      const request = AgentSqlExecuteRequest(
        agentId: ' agent-1 ',
        sql: ' SELECT *\n FROM table\n ORDER BY id ',
        namedParams: <String, Object?>{'id': 7},
        clientToken: ' token-abc ',
        bridgeTimeoutMs: 45000,
        pagination: AgentSqlPagePagination(page: 2, pageSize: 50),
        executeOptions: AgentSqlExecuteOptions(
          maxRows: 1000,
          sqlTimeoutMs: 5000,
          executionMode: AgentSqlExecutionMode.managed,
        ),
      );

      await dataSource.postSqlExecute(request);

      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          captureAny(),
          data: captureAny(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured;

      check(captured[0]).equals('/agents/commands');
      final body = captured[1]! as Map<String, Object?>;
      final command = body['command']! as Map<String, Object?>;
      final params = command['params']! as Map<String, Object?>;
      final options = params['options']! as Map<String, Object?>;
      final pagination = body['pagination']! as Map<String, Object?>;

      check(body['agentId']).equals('agent-1');
      check(body['timeoutMs']).equals(45000);
      check(pagination['page']).equals(2);
      check(pagination['pageSize']).equals(50);
      check(pagination['page_size']).equals(50);
      check(command['jsonrpc']).equals('2.0');
      check(command['method']).equals('sql.execute');
      check(command['id']).isA<String>();
      check(params['sql']).equals('SELECT * FROM table ORDER BY id');
      final namedParams = params['params']! as Map<String, Object?>;
      check(namedParams['id']).equals(7);
      check(params['client_token']).equals('token-abc');
      check(options['max_rows']).equals(1000);
      check(options['timeout_ms']).equals(5000);
      check(options['execution_mode']).equals('managed');

      final httpOptions = captured[2]! as Options;
      final expectedReceive = agentSqlHttpReceiveTimeout(
        bridgeTimeoutMs: request.bridgeTimeoutMs,
      );
      check(httpOptions.receiveTimeout).equals(expectedReceive);
      check(httpOptions.sendTimeout).equals(expectedReceive);
    },
  );

  test(
    'uses default HTTP receive timeout when bridgeTimeoutMs is null',
    () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/agents/commands'),
          data: const <String, dynamic>{},
        ),
      );

      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
      );

      await dataSource.postSqlExecute(request);

      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          captureAny(),
          data: captureAny(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured;

      final httpOptions = captured[2]! as Options;
      check(
        httpOptions.receiveTimeout,
      ).equals(kAgentSqlHttpDefaultReceiveTimeout);
      check(httpOptions.sendTimeout).equals(kAgentSqlHttpDefaultReceiveTimeout);
    },
  );

  test(
    'omits client_token from rpc params when clientToken is null',
    () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/agents/commands'),
          data: const <String, dynamic>{},
        ),
      );

      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
      );

      await dataSource.postSqlExecute(request);

      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          captureAny(),
          data: captureAny(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured;

      final body = captured[1]! as Map<String, Object?>;
      final command = body['command']! as Map<String, Object?>;
      final params = command['params']! as Map<String, Object?>;

      check(params.containsKey('client_token')).isFalse();
    },
  );

  test(
    'omits named params key when namedParams is empty',
    () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/agents/commands'),
          data: const <String, dynamic>{},
        ),
      );

      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
      );

      await dataSource.postSqlExecute(request);

      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          captureAny(),
          data: captureAny(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured;

      final body = captured[1]! as Map<String, Object?>;
      final command = body['command']! as Map<String, Object?>;
      final params = command['params']! as Map<String, Object?>;

      check(params.containsKey('params')).isFalse();
    },
  );
}
