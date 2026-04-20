import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_meta/data/models/client_token_policy_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientTokenPolicyResponseDto.fromResult', () {
    test('parses snake_case shape with explicit allow-lists', () {
      final dto = ClientTokenPolicyResponseDto.fromResult(<String, Object?>{
        'token_id': 'abc-token',
        'all_tables': false,
        'all_views': false,
        'all_permissions': false,
        'table_rules': <String>['vendas', 'clientes'],
        'view_rules': <String>['vw_resumo'],
        'permission_rules': <String>['read', 'write'],
        'revoked': false,
      });
      check(dto.tokenIdentifier).equals('abc-token');
      check(dto.allTables).isFalse();
      check(dto.tableRules.length).equals(2);
      check(dto.viewRules.first).equals('vw_resumo');
      check(dto.permissionRules.contains('read')).isTrue();
    });

    test('parses camelCase shape with all_* flags true', () {
      final dto = ClientTokenPolicyResponseDto.fromResult(<String, Object?>{
        'tokenIdentifier': 'jwt-id',
        'allTables': true,
        'allViews': true,
        'allPermissions': true,
        'tableRules': const <String>[],
        'viewRules': const <String>[],
        'permissionRules': const <String>[],
        'revoked': true,
        'revokedAt': '2026-04-01T00:00:00.000Z',
      });
      check(dto.tokenIdentifier).equals('jwt-id');
      check(dto.allTables).isTrue();
      check(dto.revoked).isTrue();
      check(dto.revokedAt).isNotNull();
    });

    test('toEntity surfaces hasFullAccess when every flag is set', () {
      final dto = ClientTokenPolicyResponseDto.fromResult(<String, Object?>{
        'token_id': 't',
        'all_tables': true,
        'all_views': true,
        'all_permissions': true,
        'revoked': false,
      });
      check(dto.toEntity().hasFullAccess).isTrue();
    });

    test('falls back to empty lists / false flags on missing fields', () {
      final dto = ClientTokenPolicyResponseDto.fromResult(
        const <String, Object?>{},
      );
      check(dto.tokenIdentifier).equals('');
      check(dto.allTables).isFalse();
      check(dto.tableRules.isEmpty).isTrue();
    });
  });
}
