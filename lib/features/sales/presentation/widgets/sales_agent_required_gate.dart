import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

class SalesAgentRequiredGate extends StatelessWidget {
  const SalesAgentRequiredGate({
    required this.selectedAgentId,
    required this.child,
    super.key,
  });

  final String? selectedAgentId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (selectedAgentId == null) {
      return AppInlineErrorPanel(
        tone: AppInlinePanelTone.informational,
        title: l10n.salesBranchRequiredTitle,
        message: l10n.salesBranchRequiredMessage,
      );
    }

    return child;
  }
}
