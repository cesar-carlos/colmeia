import 'package:colmeia/features/client_agents/presentation/localization/client_agents_presentation_message_l10n.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum ClientAgentDetailFeedbackTone { info, error }

/// Inline feedback below CTA clusters on the agent detail page.
class ClientAgentDetailFeedbackText extends StatelessWidget {
  const ClientAgentDetailFeedbackText({
    required this.message,
    required this.tone,
    super.key,
  });

  final String message;
  final ClientAgentDetailFeedbackTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (tone) {
      ClientAgentDetailFeedbackTone.info => theme.colorScheme.primary,
      ClientAgentDetailFeedbackTone.error => theme.colorScheme.error,
    };
    return Text(
      message,
      style: theme.textTheme.bodySmall?.copyWith(color: color),
    );
  }
}

String? localizeClientAgentDetailPresentationMessage(
  ClientAgentsPresentationMessage? message,
  AppLocalizations l10n,
) {
  if (message == null) {
    return null;
  }
  return localizeClientAgentsPresentationMessage(message, l10n);
}
