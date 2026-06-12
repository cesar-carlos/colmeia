import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

class ClientAgentsRequestAccessRow extends StatelessWidget {
  const ClientAgentsRequestAccessRow({
    required this.index,
    required this.agentIdController,
    required this.clientTokenController,
    required this.obscureToken,
    required this.l10n,
    required this.tokens,
    required this.onToggleObscure,
    required this.onAgentIdChanged,
    required this.onTokenChanged,
    required this.onFieldSubmitted,
    required this.canRemove,
    required this.onRemove,
    super.key,
  });

  final int index;
  final TextEditingController agentIdController;
  final TextEditingController clientTokenController;
  final bool obscureToken;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final VoidCallback onToggleObscure;
  final ValueChanged<String> onAgentIdChanged;
  final ValueChanged<String> onTokenChanged;
  final VoidCallback onFieldSubmitted;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppSectionCard(
      padding: EdgeInsets.all(tokens.gapMd),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.clientAgentsRequestAccessRowTitle(index + 1),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: l10n.clientAgentsRequestAccessRemoveRow,
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          SizedBox(height: tokens.gapSm),
          AppTextField(
            controller: agentIdController,
            label: l10n.clientAgentsAgentIdsLabel,
            hintText: '11111111-1111-1111-1111-111111111111',
            textInputAction: TextInputAction.next,
            onChanged: onAgentIdChanged,
            onFieldSubmitted: (_) => onFieldSubmitted(),
          ),
          SizedBox(height: tokens.gapSm),
          AppTextField(
            controller: clientTokenController,
            label: l10n.clientAgentsClientTokenLabel,
            hintText: l10n.clientAgentsClientTokenHint,
            obscureText: obscureToken,
            textInputAction: TextInputAction.done,
            onChanged: onTokenChanged,
            onFieldSubmitted: (_) => onFieldSubmitted(),
            suffix: IconButton(
              tooltip: obscureToken
                  ? l10n.clientAgentsClientTokenShow
                  : l10n.clientAgentsClientTokenHide,
              onPressed: onToggleObscure,
              icon: Icon(
                obscureToken
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
