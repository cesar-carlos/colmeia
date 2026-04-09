import 'package:flutter/foundation.dart';

/// One row from the "request access" form (agent id + optional local token).
@immutable
class ClientAgentAccessRequestRowInput {
  const ClientAgentAccessRequestRowInput({
    required this.agentIdRaw,
    required this.clientTokenRaw,
  });

  final String agentIdRaw;
  final String clientTokenRaw;
}
