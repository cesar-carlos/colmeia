import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_meta/application/agent_rpc_capabilities_registry.dart';
import 'package:colmeia/features/agent_meta/application/usecases/discover_agent_rpc_methods_use_case.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_rpc_descriptor.dart';

abstract interface class ClientAgentDetailAgentMetaHost {
  bool get isDisposed;

  void setAgentRpcDescriptor(AgentRpcDescriptor? descriptor);

  void setDiscoveringRpc({required bool value});

  void notifyAgentMetaChanged();
}

/// Owns `rpc.discover` hydration and capability gating for the detail screen.
class ClientAgentDetailAgentMetaCoordinator {
  ClientAgentDetailAgentMetaCoordinator({
    required this._host,
    required this._discoverAgentRpcMethodsUseCase,
    this._agentRpcCapabilitiesRegistry,
  });

  final ClientAgentDetailAgentMetaHost _host;
  final DiscoverAgentRpcMethodsUseCase _discoverAgentRpcMethodsUseCase;
  final AgentRpcCapabilitiesRegistry? _agentRpcCapabilitiesRegistry;

  AgentRpcDescriptor? _agentRpcDescriptor;
  int _rpcDiscoveryGeneration = 0;

  AgentRpcDescriptor? get agentRpcDescriptor => _agentRpcDescriptor;

  bool agentSupportsRpcMethod(String method) {
    final descriptor = _agentRpcDescriptor;
    if (descriptor == null || descriptor.isEmpty) {
      return true;
    }
    return descriptor.supportsMethod(method);
  }

  Future<void> discoverAgentRpcMethods({required String agentId}) async {
    final generation = ++_rpcDiscoveryGeneration;
    final registry = _agentRpcCapabilitiesRegistry;
    if (registry != null) {
      final cached = registry.descriptorFor(agentId);
      if (cached != null) {
        _agentRpcDescriptor = cached;
        _host.setAgentRpcDescriptor(cached);
      }
    }
    _host
      ..setDiscoveringRpc(value: true)
      ..notifyAgentMetaChanged();
    try {
      final result = await _discoverAgentRpcMethodsUseCase(agentId: agentId);
      if (_host.isDisposed || generation != _rpcDiscoveryGeneration) {
        return;
      }
      result.fold(
        (descriptor) {
          _agentRpcDescriptor = descriptor;
          _host.setAgentRpcDescriptor(descriptor);
          registry?.put(agentId, descriptor);
        },
        (failure) {
          AppLogger.info(
            'rpc.discover failed; treating agent as feature-permissive',
            context: <String, Object?>{
              'operation': 'discoverAgentRpcMethods',
              'agentId': agentId,
              'technicalMessage': failure.message,
            },
          );
        },
      );
    } finally {
      if (!_host.isDisposed && generation == _rpcDiscoveryGeneration) {
        _host
          ..setDiscoveringRpc(value: false)
          ..notifyAgentMetaChanged();
      }
    }
  }

  void reset() {
    _agentRpcDescriptor = null;
    _host.setAgentRpcDescriptor(null);
  }
}
