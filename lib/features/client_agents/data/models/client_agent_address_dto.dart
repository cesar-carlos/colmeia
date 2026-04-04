import 'package:colmeia/features/client_agents/domain/entities/agent_profile_address.dart';

class ClientAgentAddressDto {
  const ClientAgentAddressDto({
    this.street,
    this.number,
    this.district,
    this.postalCode,
    this.city,
    this.state,
  });

  factory ClientAgentAddressDto.fromJson(Map<String, dynamic> json) {
    return ClientAgentAddressDto(
      street: json['street'] as String?,
      number: json['number'] as String?,
      district: json['district'] as String?,
      postalCode: json['postalCode'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
    );
  }

  final String? street;
  final String? number;
  final String? district;
  final String? postalCode;
  final String? city;
  final String? state;

  AgentProfileAddress toEntity() {
    return AgentProfileAddress(
      street: street,
      number: number,
      district: district,
      postalCode: postalCode,
      city: city,
      state: state,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'street': street,
      'number': number,
      'district': district,
      'postalCode': postalCode,
      'city': city,
      'state': state,
    };
  }
}
