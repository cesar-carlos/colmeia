import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_meta/data/models/rpc_discover_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RpcDiscoverResponseDto.fromResult', () {
    test('extracts method names from the OpenRPC document', () {
      final dto = RpcDiscoverResponseDto.fromResult(<String, Object?>{
        'openrpc': '1.2.6',
        'info': const <String, Object?>{
          'title': 'plug_agente',
          'version': '2.8.0',
        },
        'methods': <Map<String, Object?>>[
          <String, Object?>{'name': 'sql.execute'},
          <String, Object?>{'name': 'agent.getProfile'},
          <String, Object?>{'name': 'client_token.getPolicy'},
        ],
      });
      check(dto.methods.length).equals(3);
      check(dto.methods.contains('sql.execute')).isTrue();
      check(dto.title).equals('plug_agente');
      check(dto.version).equals('2.8.0');
      check(dto.openRpcVersion).equals('1.2.6');
    });

    test('tolerates plain string entries instead of objects', () {
      final dto = RpcDiscoverResponseDto.fromResult(<String, Object?>{
        'methods': <String>['sql.execute', 'rpc.discover'],
      });
      check(dto.methods.length).equals(2);
    });

    test('returns empty descriptor when methods is absent', () {
      final dto = RpcDiscoverResponseDto.fromResult(
        const <String, Object?>{},
      );
      check(dto.methods.isEmpty).isTrue();
      check(dto.toEntity().isEmpty).isTrue();
    });

    test('supportsMethod via toEntity()', () {
      final dto = RpcDiscoverResponseDto.fromResult(<String, Object?>{
        'methods': <Map<String, Object?>>[
          <String, Object?>{'name': 'sql.execute'},
        ],
      });
      final entity = dto.toEntity();
      check(entity.supportsMethod('sql.execute')).isTrue();
      check(entity.supportsMethod('client_token.getPolicy')).isFalse();
    });
  });
}
