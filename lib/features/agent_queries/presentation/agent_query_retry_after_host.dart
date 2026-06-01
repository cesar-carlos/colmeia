import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Hosts a [RetryAfterGate] for agent-query surfaces (Sales charts, reports).
mixin AgentQueryRetryAfterHost<T extends StatefulWidget> on State<T> {
  final RetryAfterGate agentQueryRetryAfterGate = RetryAfterGate();

  @override
  void initState() {
    super.initState();
    agentQueryRetryAfterGate.addListener(_onAgentQueryRetryGateChanged);
  }

  @override
  void dispose() {
    agentQueryRetryAfterGate
      ..removeListener(_onAgentQueryRetryGateChanged)
      ..dispose();
    super.dispose();
  }

  void _onAgentQueryRetryGateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get isAgentQueryRetryCooldown => !agentQueryRetryAfterGate.isOpen;

  String? agentQueryRetryCountdownLabel(AppLocalizations l10n) {
    final remaining = agentQueryRetryAfterGate.remaining;
    if (remaining == null) {
      return null;
    }
    return l10n.appInlineErrorRetryCountdown(remaining.inSeconds);
  }

  @protected
  void onAgentQueryLoadFailure(AppFailure? failure) {
    if (failure == null) {
      return;
    }
    armAgentQueryRetryAfterGate(agentQueryRetryAfterGate, failure);
  }
}
