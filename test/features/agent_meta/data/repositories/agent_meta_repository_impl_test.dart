import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/network/bridge_rpc_response.dart';
import 'package:colmeia/features/agent_meta/data/datasources/agent_meta_remote_datasource.dart';
import 'package:colmeia/features/agent_meta/data/models/agent_get_profile_response_dto.dart';
import 'package:colmeia/features/agent_meta/data/models/client_token_policy_response_dto.dart';
import 'package:colmeia/features/agent_meta/data/models/rpc_discover_response_dto.dart';
import 'package:colmeia/features/agent_meta/data/repositories/agent_meta_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAgentMetaRemoteDataSource extends Mock
    implements AgentMetaRemoteDataSource {}

void main() {
  late _MockAgentMetaRemoteDataSource remote;
  late AgentMetaRepositoryImpl sut;

  setUp(() {
    remote = _MockAgentMetaRemoteDataSource();
    when(() => remote.transportLabel).thenReturn('socket');
    sut = AgentMetaRepositoryImpl(remote);
  });

  group('getAgentProfile', () {
    test('returns a snapshot on success', () async {
      when(
        () => remote.agentGetProfile(
          agentId: any(named: 'agentId'),
          clientToken: any(named: 'clientToken'),
        ),
      ).thenAnswer(
        (_) async => AgentGetProfileResponseDto.fromResult(
          <String, Object?>{
            'agent_id': 'a',
            'name': 'Plug',
            'profile_version': 7,
          },
        ),
      );

      final result = await sut.getAgentProfile(agentId: 'a');
      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.profileVersion).equals(7);
    });

    test('returns ValidationFailure on empty agent id', () async {
      final result = await sut.getAgentProfile(agentId: '   ');
      check(result.exceptionOrNull()).isA<ValidationFailure>();
      verifyNever(
        () => remote.agentGetProfile(
          agentId: any(named: 'agentId'),
          clientToken: any(named: 'clientToken'),
        ),
      );
    });

    test('maps BridgeRpcException to RpcFailure', () async {
      when(
        () => remote.agentGetProfile(
          agentId: any(named: 'agentId'),
          clientToken: any(named: 'clientToken'),
        ),
      ).thenThrow(
        BridgeRpcException(
          const BridgeRpcErrorDetails(
            userMessage: 'Agent denied the request.',
            message: 'Agent denied the request.',
            code: '-32001',
            reason: 'agent_access_denied',
          ),
        ),
      );

      final result = await sut.getAgentProfile(agentId: 'a');
      check(result.isError()).isTrue();
      final failure = result.exceptionOrNull();
      check(failure).isA<RpcFailure>();
      check(failure?.context['transport']).equals('socket');
      check(failure?.context['rpcCode']).equals('-32001');
    });
  });

  group('getClientTokenPolicy', () {
    test('returns supported snapshot on success', () async {
      when(
        () => remote.clientTokenGetPolicy(
          agentId: any(named: 'agentId'),
          clientToken: any(named: 'clientToken'),
        ),
      ).thenAnswer(
        (_) async => ClientTokenPolicyResponseDto.fromResult(
          <String, Object?>{
            'token_id': 'tok',
            'all_tables': true,
            'all_views': true,
            'all_permissions': true,
            'revoked': false,
          },
        ),
      );

      final result = await sut.getClientTokenPolicy(
        agentId: 'a',
        clientToken: 'tok',
      );
      check(result.isSuccess()).isTrue();
      final snapshot = result.getOrNull()!;
      check(snapshot.supported).isTrue();
      check(snapshot.policy?.hasFullAccess).equals(true);
    });

    test(
      'maps -32601 method_not_found to unsupported snapshot (no error)',
      () async {
        when(
          () => remote.clientTokenGetPolicy(
            agentId: any(named: 'agentId'),
            clientToken: any(named: 'clientToken'),
          ),
        ).thenThrow(
          BridgeRpcException(
            const BridgeRpcErrorDetails(
              userMessage: 'method not found',
              message: 'method not found',
              code: '-32601',
              reason: 'method_not_found',
            ),
          ),
        );

        final result = await sut.getClientTokenPolicy(
          agentId: 'a',
          clientToken: 'tok',
        );
        check(result.isSuccess()).isTrue();
        final snapshot = result.getOrNull()!;
        check(snapshot.supported).isFalse();
        check(snapshot.policy).isNull();
      },
    );

    test('returns ValidationFailure on empty token', () async {
      final result = await sut.getClientTokenPolicy(
        agentId: 'a',
        clientToken: '   ',
      );
      check(result.exceptionOrNull()).isA<ValidationFailure>();
    });
  });

  group('discoverAgentRpc', () {
    test('returns the RPC catalogue on success', () async {
      when(
        () => remote.rpcDiscover(agentId: any(named: 'agentId')),
      ).thenAnswer(
        (_) async => RpcDiscoverResponseDto.fromResult(<String, Object?>{
          'methods': <Map<String, Object?>>[
            <String, Object?>{'name': 'sql.execute'},
            <String, Object?>{'name': 'agent.getProfile'},
          ],
        }),
      );

      final result = await sut.discoverAgentRpc(agentId: 'a');
      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.supportsMethod('sql.execute')).equals(true);
    });

    test(
      'maps -32601 to empty descriptor (Success)',
      () async {
        when(
          () => remote.rpcDiscover(agentId: any(named: 'agentId')),
        ).thenThrow(
          BridgeRpcException(
            const BridgeRpcErrorDetails(
              userMessage: 'method not found',
              message: 'method not found',
              code: '-32601',
              reason: 'method_not_found',
            ),
          ),
        );

        final result = await sut.discoverAgentRpc(agentId: 'a');
        check(result.isSuccess()).isTrue();
        check(result.getOrNull()?.isEmpty).equals(true);
      },
    );
  });
}
