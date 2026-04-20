import 'package:colmeia/features/agent_meta/domain/entities/agent_rpc_descriptor.dart';

/// Wire result of `rpc.discover`. The agent returns an OpenRPC document; we
/// only extract the method name list + a couple of metadata fields.
class RpcDiscoverResponseDto {
  const RpcDiscoverResponseDto({
    required this.methods,
    this.openRpcVersion,
    this.title,
    this.version,
    this.raw = const <String, Object?>{},
  });

  factory RpcDiscoverResponseDto.fromResult(Map<String, Object?> result) {
    final methodsRaw = result['methods'];
    final methodNames = <String>{};
    if (methodsRaw is List<dynamic>) {
      for (final entry in methodsRaw) {
        if (entry is Map<String, Object?>) {
          final name = entry['name']?.toString().trim();
          if (name != null && name.isNotEmpty) {
            methodNames.add(name);
          }
        } else if (entry is Map) {
          final name = entry['name']?.toString().trim();
          if (name != null && name.isNotEmpty) {
            methodNames.add(name);
          }
        } else if (entry is String) {
          final trimmed = entry.trim();
          if (trimmed.isNotEmpty) {
            methodNames.add(trimmed);
          }
        }
      }
    }

    String? openRpcVersion;
    String? title;
    String? version;
    final info = result['info'];
    if (info is Map) {
      title = info['title']?.toString();
      version = info['version']?.toString();
    }
    openRpcVersion = result['openrpc']?.toString();

    return RpcDiscoverResponseDto(
      methods: methodNames,
      openRpcVersion: openRpcVersion,
      title: title,
      version: version,
      raw: result,
    );
  }

  final Set<String> methods;
  final String? openRpcVersion;
  final String? title;
  final String? version;
  final Map<String, Object?> raw;

  AgentRpcDescriptor toEntity() {
    return AgentRpcDescriptor(
      methods: methods,
      openRpcVersion: openRpcVersion,
      title: title,
      version: version,
      raw: raw,
    );
  }
}
