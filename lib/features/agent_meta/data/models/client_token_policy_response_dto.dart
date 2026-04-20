import 'package:colmeia/features/agent_meta/domain/entities/client_token_policy.dart';

/// Wire result of `client_token.getPolicy` (per
/// `plug_agente/docs/communication/schemas/rpc.result.client-token-get-policy.schema.json`).
///
/// Field names are tolerant: agents on profile 2.7 sometimes use
/// `snake_case`, and the JSON Schema in 2.8 added camel-cased aliases.
class ClientTokenPolicyResponseDto {
  const ClientTokenPolicyResponseDto({
    required this.tokenIdentifier,
    required this.allTables,
    required this.allViews,
    required this.allPermissions,
    required this.tableRules,
    required this.viewRules,
    required this.permissionRules,
    required this.revoked,
    this.revokedAt,
    this.payload = const <String, Object?>{},
  });

  factory ClientTokenPolicyResponseDto.fromResult(
    Map<String, Object?> result,
  ) {
    return ClientTokenPolicyResponseDto(
      tokenIdentifier:
          (result['token_id'] ?? result['tokenIdentifier'] ?? result['jti'])
                  ?.toString() ??
              '',
      allTables: _asBool(
        result['all_tables'] ?? result['allTables'],
        fallback: false,
      ),
      allViews: _asBool(
        result['all_views'] ?? result['allViews'],
        fallback: false,
      ),
      allPermissions: _asBool(
        result['all_permissions'] ?? result['allPermissions'],
        fallback: false,
      ),
      tableRules: _asStringList(
        result['table_rules'] ?? result['tables'] ?? result['tableRules'],
      ),
      viewRules: _asStringList(
        result['view_rules'] ?? result['views'] ?? result['viewRules'],
      ),
      permissionRules: _asStringList(
        result['permission_rules'] ??
            result['permissions'] ??
            result['permissionRules'],
      ),
      revoked: _asBool(result['revoked'], fallback: false),
      revokedAt: _parseDate(result['revoked_at'] ?? result['revokedAt']),
      payload: result,
    );
  }

  final String tokenIdentifier;
  final bool allTables;
  final bool allViews;
  final bool allPermissions;
  final List<String> tableRules;
  final List<String> viewRules;
  final List<String> permissionRules;
  final bool revoked;
  final DateTime? revokedAt;
  final Map<String, Object?> payload;

  ClientTokenPolicy toEntity() {
    return ClientTokenPolicy(
      tokenIdentifier: tokenIdentifier,
      allTables: allTables,
      allViews: allViews,
      allPermissions: allPermissions,
      tableRules: tableRules,
      viewRules: viewRules,
      permissionRules: permissionRules,
      revoked: revoked,
      revokedAt: revokedAt,
      payload: payload,
    );
  }

  static bool _asBool(Object? raw, {required bool fallback}) {
    if (raw is bool) {
      return raw;
    }
    if (raw is num) {
      return raw != 0;
    }
    if (raw is String) {
      final s = raw.trim().toLowerCase();
      if (s == 'true') {
        return true;
      }
      if (s == 'false') {
        return false;
      }
    }
    return fallback;
  }

  static List<String> _asStringList(Object? raw) {
    if (raw is! List<dynamic>) {
      return const <String>[];
    }
    return raw
        .map((item) => item?.toString().trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String) {
      return DateTime.tryParse(raw)?.toUtc();
    }
    return null;
  }
}
