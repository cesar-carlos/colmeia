import 'package:colmeia/features/client_agents/domain/entities/owner_approved_client.dart';

class OwnerApprovedClientDto {
  const OwnerApprovedClientDto({
    required this.clientId,
    required this.clientName,
    this.clientEmail,
    this.accountStatus,
    this.approvedAt,
  });

  factory OwnerApprovedClientDto.fromJson(Map<String, dynamic> json) {
    final client = (json['client'] as Map<String, dynamic>?) ?? json;
    final clientName =
        _readOptionalString(
          json,
          const <String>['clientName', 'client_name', 'name'],
        ) ??
        _readOptionalString(
          client,
          const <String>['name', 'fullName', 'full_name', 'firstName'],
        ) ??
        _readOptionalString(
          json,
          const <String>['clientEmail', 'client_email', 'email'],
        ) ??
        _readOptionalString(client, const <String>['email']) ??
        'Cliente';
    return OwnerApprovedClientDto(
      clientId:
          _readOptionalString(json, const <String>['clientId', 'client_id']) ??
          _readOptionalString(client, const <String>['id', 'clientId']) ??
          '',
      clientName: clientName,
      clientEmail:
          _readOptionalString(
            json,
            const <String>['clientEmail', 'client_email', 'email'],
          ) ??
          _readOptionalString(client, const <String>['email']),
      accountStatus:
          _readOptionalString(json, const <String>['status']) ??
          _readOptionalString(client, const <String>['status']),
      approvedAt: DateTime.tryParse(
        _readOptionalString(
              json,
              const <String>['approvedAt', 'createdAt', 'updatedAt'],
            ) ??
            '',
      ),
    );
  }

  final String clientId;
  final String clientName;
  final String? clientEmail;
  final String? accountStatus;
  final DateTime? approvedAt;

  OwnerApprovedClient toEntity() {
    return OwnerApprovedClient(
      clientId: clientId,
      clientName: clientName,
      clientEmail: clientEmail,
      accountStatus: accountStatus,
      approvedAt: approvedAt,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'status': accountStatus,
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }
}

String? _readOptionalString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final raw = json[key];
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
  }
  return null;
}
