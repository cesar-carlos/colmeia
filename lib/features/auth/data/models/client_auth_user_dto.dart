import 'package:colmeia/shared/data/json/wrapped_json_reader.dart';
import 'package:colmeia/shared/identity/client_account_status.dart';

class ClientAuthUserDto {
  const ClientAuthUserDto({
    required this.id,
    required this.email,
    required this.accountStatus,
    this.role,
    this.firstName,
    this.lastName,
    this.mobile,
    this.thumbnailUrl,
  });

  factory ClientAuthUserDto.fromJson(Map<String, dynamic> json) {
    return ClientAuthUserDto(
      id: readRequiredString(
        json,
        const <String>[
          'id',
          'userId',
          'user_id',
          'clientId',
          'client_id',
          'sub',
        ],
        logicalName: 'id',
      ),
      email: readRequiredString(
        json,
        const <String>['email'],
        logicalName: 'email',
      ),
      accountStatus: ClientAccountStatusParsing.fromRaw(
        readOptionalString(json, const <String>['status']),
      ),
      role: readOptionalString(json, const <String>['role']),
      firstName: _readFirstName(json),
      lastName: _readLastName(json),
      mobile: readOptionalString(
        json,
        const <String>['mobile', 'celular', 'phone'],
      ),
      thumbnailUrl: readOptionalString(
        json,
        const <String>['thumbnailUrl', 'thumbnail_url'],
      ),
    );
  }

  final String id;
  final String email;
  final ClientAccountStatus accountStatus;
  final String? role;
  final String? firstName;
  final String? lastName;
  final String? mobile;
  final String? thumbnailUrl;

  String get displayName {
    final fullName = <String?>[firstName, lastName]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' ');
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return email;
  }

  String get resolvedRoleLabel {
    final normalizedRole = role?.trim();
    if (normalizedRole != null && normalizedRole.isNotEmpty) {
      return '$normalizedRole (${accountStatus.wireValue})';
    }

    return accountStatus.wireValue;
  }

  static String? _readFirstName(Map<String, dynamic> json) {
    final direct = readOptionalString(
      json,
      const <String>['name', 'firstName', 'first_name'],
    );
    if (direct != null) {
      return direct;
    }

    final fullName = readOptionalString(
      json,
      const <String>['fullName', 'full_name'],
    );
    if (fullName == null) {
      return null;
    }

    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
    return parts.isEmpty ? null : parts.first;
  }

  static String? _readLastName(Map<String, dynamic> json) {
    final direct = readOptionalString(
      json,
      const <String>['lastName', 'last_name'],
    );
    if (direct != null) {
      return direct;
    }

    final fullName = readOptionalString(
      json,
      const <String>['fullName', 'full_name'],
    );
    if (fullName == null) {
      return null;
    }

    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.length < 2) {
      return null;
    }

    return parts.skip(1).join(' ');
  }
}
