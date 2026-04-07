import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

class ClientAgentsRequestAccessTab extends StatefulWidget {
  const ClientAgentsRequestAccessTab({
    required this.onRequestAccess,
    required this.onClearMessages,
    required this.isMutating,
    super.key,
    this.initialDraft = '',
    this.onDraftChanged,
  });

  final Future<bool> Function(Set<String> agentIds) onRequestAccess;
  final VoidCallback onClearMessages;
  final bool isMutating;
  final String initialDraft;
  final ValueChanged<String>? onDraftChanged;

  @override
  State<ClientAgentsRequestAccessTab> createState() =>
      _ClientAgentsRequestAccessTabState();
}

class _ClientAgentsRequestAccessTabState
    extends State<ClientAgentsRequestAccessTab> {
  static final RegExp _uuidPattern = RegExp(
    '^[0-9a-fA-F]{8}-'
    '[0-9a-fA-F]{4}-'
    '[1-5][0-9a-fA-F]{3}-'
    '[89abAB][0-9a-fA-F]{3}-'
    r'[0-9a-fA-F]{12}$',
  );

  final TextEditingController _agentIdsController = TextEditingController();
  String? _validationMessage;
  String? _inputNoteMessage;

  @override
  void initState() {
    super.initState();
    _agentIdsController.text = widget.initialDraft;
  }

  @override
  void didUpdateWidget(covariant ClientAgentsRequestAccessTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDraft != widget.initialDraft &&
        widget.initialDraft != _agentIdsController.text) {
      _agentIdsController.text = widget.initialDraft;
    }
  }

  @override
  void dispose() {
    _agentIdsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l10n.clientAgentsRequestAccessIntro1),
        SizedBox(height: tokens.gapSm),
        Text(l10n.clientAgentsRequestAccessIntro2),
        SizedBox(height: tokens.gapMd),
        AppTextField(
          controller: _agentIdsController,
          label: l10n.clientAgentsAgentIdsLabel,
          hintText: '11111111-1111-1111-1111-111111111111',
          maxLines: 4,
          minLines: 3,
          textInputAction: TextInputAction.newline,
          onChanged: (_) {
            if (_validationMessage != null || _inputNoteMessage != null) {
              setState(() {
                _validationMessage = null;
                _inputNoteMessage = null;
              });
            }
            widget.onClearMessages();
            widget.onDraftChanged?.call(_agentIdsController.text);
          },
        ),
        if (_validationMessage case final String message) ...<Widget>[
          SizedBox(height: tokens.gapSm),
          Text(
            message,
            style:
                Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
        if (_inputNoteMessage case final String message) ...<Widget>[
          SizedBox(height: tokens.gapSm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
        SizedBox(height: tokens.gapMd),
        AppPrimaryButton(
          label: l10n.clientAgentsRequestAccessCta,
          icon: const Icon(Icons.send_rounded),
          isLoading: widget.isMutating,
          onPressed: widget.isMutating ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final parsed = _parseAgentIds(_agentIdsController.text);
    if (parsed.validAgentIds.isEmpty) {
      setState(() {
        _validationMessage = parsed.invalidAgentIds.isEmpty
            ? l10n.clientAgentsValidationNeedOneValidId
            : l10n.clientAgentsValidationInvalidIds(
                parsed.invalidAgentIds.join(', '),
              );
        _inputNoteMessage = null;
      });
      return;
    }

    final accepted = await widget.onRequestAccess(parsed.validAgentIds);
    if (!mounted) {
      return;
    }

    if (accepted) {
      _agentIdsController.clear();
      widget.onDraftChanged?.call('');
    }

    setState(() {
      _validationMessage = null;
      _inputNoteMessage = parsed.duplicatedAgentIds.isEmpty
          ? null
          : l10n.clientAgentsDuplicatedIdsNote(
              parsed.duplicatedAgentIds.join(', '),
            );
    });
  }

  _ParsedAgentIds _parseAgentIds(String rawValue) {
    final rawAgentIds = rawValue
        .split(RegExp(r'[\s,;]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    if (rawAgentIds.isEmpty) {
      return const _ParsedAgentIds();
    }

    final validAgentIds = <String>{};
    final duplicatedAgentIds = <String>{};
    final invalidAgentIds = <String>[];

    for (final agentId in rawAgentIds) {
      if (!_uuidPattern.hasMatch(agentId)) {
        invalidAgentIds.add(agentId);
        continue;
      }
      if (!validAgentIds.add(agentId)) {
        duplicatedAgentIds.add(agentId);
      }
    }

    return _ParsedAgentIds(
      validAgentIds: validAgentIds,
      duplicatedAgentIds: duplicatedAgentIds.toSet(),
      invalidAgentIds: invalidAgentIds,
    );
  }
}

class _ParsedAgentIds {
  const _ParsedAgentIds({
    this.validAgentIds = const <String>{},
    this.duplicatedAgentIds = const <String>{},
    this.invalidAgentIds = const <String>[],
  });

  final Set<String> validAgentIds;
  final Set<String> duplicatedAgentIds;
  final List<String> invalidAgentIds;
}
