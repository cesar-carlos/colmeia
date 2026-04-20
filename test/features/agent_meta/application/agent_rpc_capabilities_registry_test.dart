import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_meta/application/agent_rpc_capabilities_registry.dart';
import 'package:colmeia/features/agent_meta/application/usecases/discover_agent_rpc_methods_use_case.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_rpc_descriptor.dart';
import 'package:colmeia/features/agent_meta/domain/entities/client_token_policy.dart';
import 'package:colmeia/features/agent_meta/domain/repositories/agent_meta_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  group('AgentRpcCapabilitiesRegistry', () {
    test(
      'prefetch fans out one discover per unknown agent and populates '
      'the cache',
      () async {
        final repository = _ProgrammableMetaRepository(
          discoverByAgentId: <String, AgentRpcDescriptor>{
            'a1': const AgentRpcDescriptor(methods: <String>{'sql.execute'}),
            'a2': const AgentRpcDescriptor(
              methods: <String>{'agent.getProfile'},
            ),
          },
        );
        final registry = AgentRpcCapabilitiesRegistry(
          discoverAgentRpcMethodsUseCase: DiscoverAgentRpcMethodsUseCase(
            repository,
          ),
        );

        await registry.prefetch(<String>['a1', 'a2']);

        check(registry.descriptorFor('a1')!.methods).deepEquals(
          <String>{'sql.execute'},
        );
        check(registry.descriptorFor('a2')!.methods).deepEquals(
          <String>{'agent.getProfile'},
        );
        check(registry.cachedAgentCount).equals(2);
        check(repository.discoverCallCount).equals(2);
      },
    );

    test('prefetch deduplicates already-cached agents', () async {
      final repository = _ProgrammableMetaRepository(
        discoverByAgentId: <String, AgentRpcDescriptor>{
          'a1': const AgentRpcDescriptor(methods: <String>{'sql.execute'}),
        },
      );
      final registry = AgentRpcCapabilitiesRegistry(
        discoverAgentRpcMethodsUseCase: DiscoverAgentRpcMethodsUseCase(
          repository,
        ),
      );

      await registry.prefetch(<String>['a1']);
      await registry.prefetch(<String>['a1', 'a1', '   a1   ']);

      check(repository.discoverCallCount).equals(1);
    });

    test(
      'concurrent ensure() calls share a single in-flight request',
      () async {
        final completer = Completer<AppResult<AgentRpcDescriptor>>();
        final repository = _ProgrammableMetaRepository(
          // Custom future for "a1" so we can control completion order.
          discoverFuture: (agentId) {
            if (agentId == 'a1') return completer.future;
            return null;
          },
        );
        final registry = AgentRpcCapabilitiesRegistry(
          discoverAgentRpcMethodsUseCase: DiscoverAgentRpcMethodsUseCase(
            repository,
          ),
        );

        final f1 = registry.ensure('a1');
        final f2 = registry.ensure('a1');
        final f3 = registry.ensure('a1');

        completer.complete(
          const Success<AgentRpcDescriptor, AppFailure>(
            AgentRpcDescriptor(methods: <String>{'sql.execute'}),
          ),
        );

        final results = await Future.wait(<Future<AgentRpcDescriptor?>>[
          f1,
          f2,
          f3,
        ]);

        check(repository.discoverCallCount).equals(1);
        check(results.every((r) => r?.supportsMethod('sql.execute') ?? false))
            .isTrue();
      },
    );

    test('failures are swallowed and the agent stays absent', () async {
      final repository = _ProgrammableMetaRepository(
        discoverByAgentId: <String, AgentRpcDescriptor>{},
        failureByAgentId: <String, AppFailure>{
          'a1': const NetworkFailure(
            message: 'down',
            userMessage: 'down',
          ),
        },
      );
      final registry = AgentRpcCapabilitiesRegistry(
        discoverAgentRpcMethodsUseCase: DiscoverAgentRpcMethodsUseCase(
          repository,
        ),
      );

      await registry.prefetch(<String>['a1']);

      check(registry.descriptorFor('a1')).isNull();
      check(registry.supports(agentId: 'a1', method: 'sql.execute')).isNull();
      check(registry.cachedAgentCount).equals(0);
    });

    test('put() and invalidate() update the cache and notify', () {
      final registry = AgentRpcCapabilitiesRegistry(
        discoverAgentRpcMethodsUseCase: DiscoverAgentRpcMethodsUseCase(
          _ProgrammableMetaRepository(),
        ),
      );

      var notifications = 0;
      registry
        ..addListener(() => notifications++)
        ..put(
          'a1',
          const AgentRpcDescriptor(methods: <String>{'sql.execute'}),
        );
      check(notifications).equals(1);
      check(registry.supports(agentId: 'a1', method: 'sql.execute'))
          .equals(true);
      check(registry.supports(agentId: 'a1', method: 'agent.getProfile'))
          .equals(false);

      registry.invalidate(<String>['a1']);
      check(notifications).equals(2);
      check(registry.descriptorFor('a1')).isNull();
    });

    test('clear() empties the cache and notifies once', () {
      final registry = AgentRpcCapabilitiesRegistry(
        discoverAgentRpcMethodsUseCase: DiscoverAgentRpcMethodsUseCase(
          _ProgrammableMetaRepository(),
        ),
      )
        ..put(
          'a1',
          const AgentRpcDescriptor(methods: <String>{'sql.execute'}),
        )
        ..put(
          'a2',
          const AgentRpcDescriptor(methods: <String>{'agent.getProfile'}),
        );

      var notifications = 0;
      registry
        ..addListener(() => notifications++)
        ..clear();
      check(notifications).equals(1);
      check(registry.cachedAgentCount).equals(0);

      registry.clear();
      check(notifications).equals(1);
    });
  });
}

class _ProgrammableMetaRepository implements AgentMetaRepository {
  _ProgrammableMetaRepository({
    Map<String, AgentRpcDescriptor>? discoverByAgentId,
    Map<String, AppFailure>? failureByAgentId,
    Future<AppResult<AgentRpcDescriptor>>? Function(String)? discoverFuture,
  })  : _discoverByAgentId =
            discoverByAgentId ?? const <String, AgentRpcDescriptor>{},
        _failureByAgentId = failureByAgentId ?? const <String, AppFailure>{},
        _discoverFuture = discoverFuture;

  final Map<String, AgentRpcDescriptor> _discoverByAgentId;
  final Map<String, AppFailure> _failureByAgentId;
  final Future<AppResult<AgentRpcDescriptor>>? Function(String)?
  _discoverFuture;

  int discoverCallCount = 0;

  @override
  Future<AppResult<AgentRpcDescriptor>> discoverAgentRpc({
    required String agentId,
  }) {
    discoverCallCount++;
    final custom = _discoverFuture?.call(agentId);
    if (custom != null) {
      return custom;
    }
    final failure = _failureByAgentId[agentId];
    if (failure != null) {
      return Future.value(Failure<AgentRpcDescriptor, AppFailure>(failure));
    }
    final descriptor = _discoverByAgentId[agentId];
    if (descriptor != null) {
      return Future.value(
        Success<AgentRpcDescriptor, AppFailure>(descriptor),
      );
    }
    return Future.value(
      const Failure<AgentRpcDescriptor, AppFailure>(
        NetworkFailure(message: 'no stub', userMessage: 'no stub'),
      ),
    );
  }

  @override
  Future<AppResult<AgentProfileSnapshot>> getAgentProfile({
    required String agentId,
    String? clientToken,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<ClientTokenPolicySnapshot>> getClientTokenPolicy({
    required String agentId,
    required String clientToken,
  }) => throw UnimplementedError();
}
