import 'package:colmeia/features/client_agents/data/models/client_accessible_agent_dto.dart';

class ClientApprovedAgentDetailResponseDto {
  const ClientApprovedAgentDetailResponseDto({
    required this.agent,
  });

  factory ClientApprovedAgentDetailResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClientApprovedAgentDetailResponseDto(
      agent: ClientAccessibleAgentDto.fromJson(
        (json['agent'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
    );
  }

  final ClientAccessibleAgentDto agent;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'agent': agent.toJson(),
    };
  }
}
