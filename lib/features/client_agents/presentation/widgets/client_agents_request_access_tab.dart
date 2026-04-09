import 'dart:async';

import 'package:colmeia/features/client_agents/presentation/models/client_agent_access_request_row_input.dart';
import 'package:colmeia/features/client_agents/presentation/utils/client_agent_id_format.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

class ClientAgentsRequestAccessTab extends StatefulWidget {
  const ClientAgentsRequestAccessTab({
    required this.onSubmitRows,
    required this.onClearMessages,
    required this.isMutating,
    required this.onDraftSlotsChanged,
    required this.loadClientToken,
    required this.persistClientTokenDraftLine,
    super.key,
    this.initialAgentIdSlots = const <String>[''],
  });

  final List<String> initialAgentIdSlots;

  final Future<bool> Function(List<ClientAgentAccessRequestRowInput> rows)
      onSubmitRows;
  final VoidCallback onClearMessages;
  final bool isMutating;
  final ValueChanged<List<String>> onDraftSlotsChanged;
  final Future<String?> Function(String agentId) loadClientToken;
  final Future<void> Function({
    required String agentIdRaw,
    required String clientTokenRaw,
  })
  persistClientTokenDraftLine;

  @override
  State<ClientAgentsRequestAccessTab> createState() =>
      _ClientAgentsRequestAccessTabState();
}

class _RowControllers {
  _RowControllers({
    required this.agentId,
    required this.clientToken,
  });

  final TextEditingController agentId;
  final TextEditingController clientToken;
}

class _ClientAgentsRequestAccessTabState
    extends State<ClientAgentsRequestAccessTab> {
  late List<_RowControllers> _rows;
  final Set<String> _hydratedTokenForAgentId = <String>{};
  final Map<int, Timer> _persistTimersByRowIndex = <int, Timer>{};
  List<String?> _committedValidUuidPerRow = <String?>[];
  String? _validationMessage;
  String? _inputNoteMessage;
  final List<bool> _obscureToken = <bool>[];

  @override
  void initState() {
    super.initState();
    _rows = _createRowsFromSlots(widget.initialAgentIdSlots);
    _syncCommittedValidUuidsFromControllers();
    _syncObscureFlags();
    unawaited(_hydrateTokensForInitialRows());
  }

  void _syncCommittedValidUuidsFromControllers() {
    _committedValidUuidPerRow = List<String?>.generate(_rows.length, (i) {
      final t = _rows[i].agentId.text.trim();
      return isValidClientAgentId(t) ? t : null;
    });
  }

  @override
  void didUpdateWidget(covariant ClientAgentsRequestAccessTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(
      oldWidget.initialAgentIdSlots,
      widget.initialAgentIdSlots,
    )) {
      _cancelAllPersistTimers();
      _disposeRowControllers();
      _rows = _createRowsFromSlots(widget.initialAgentIdSlots);
      _hydratedTokenForAgentId.clear();
      _syncCommittedValidUuidsFromControllers();
      _syncObscureFlags();
      unawaited(_hydrateTokensForInitialRows());
    }
  }

  List<_RowControllers> _createRowsFromSlots(List<String> slots) {
    final raw = slots.isEmpty ? <String>[''] : List<String>.from(slots);
    return raw
        .map(
          (slot) => _RowControllers(
            agentId: TextEditingController(text: slot),
            clientToken: TextEditingController(),
          ),
        )
        .toList(growable: false);
  }

  void _syncObscureFlags() {
    _obscureToken
      ..clear()
      ..addAll(List<bool>.filled(_rows.length, true));
  }

  Future<void> _hydrateTokensForInitialRows() async {
    for (var i = 0; i < _rows.length; i++) {
      final id = _rows[i].agentId.text.trim();
      if (!isValidClientAgentId(id)) {
        continue;
      }
      if (_hydratedTokenForAgentId.contains(id)) {
        continue;
      }
      final token = await widget.loadClientToken(id);
      if (!mounted) {
        return;
      }
      if (token != null && token.isNotEmpty) {
        _rows[i].clientToken.text = token;
      }
      _hydratedTokenForAgentId.add(id);
    }
  }

  void _cancelPersistTimerForRow(int index) {
    _persistTimersByRowIndex.remove(index)?.cancel();
  }

  void _cancelAllPersistTimers() {
    for (final timer in _persistTimersByRowIndex.values) {
      timer.cancel();
    }
    _persistTimersByRowIndex.clear();
  }

  @override
  void dispose() {
    _cancelAllPersistTimers();
    _disposeRowControllers();
    super.dispose();
  }

  void _disposeRowControllers() {
    for (final row in _rows) {
      row.agentId.dispose();
      row.clientToken.dispose();
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  void _notifyDraftSlotsChanged() {
    widget.onDraftSlotsChanged(
      _rows.map((r) => r.agentId.text).toList(growable: false),
    );
  }

  void _schedulePersistTokenForRow(int index) {
    if (index < 0 || index >= _rows.length) {
      return;
    }
    _cancelPersistTimerForRow(index);
    _persistTimersByRowIndex[index] = Timer(
      const Duration(milliseconds: 400),
      () async {
        _persistTimersByRowIndex.remove(index);
        if (index >= _rows.length) {
          return;
        }
        await widget.persistClientTokenDraftLine(
          agentIdRaw: _rows[index].agentId.text,
          clientTokenRaw: _rows[index].clientToken.text,
        );
      },
    );
  }

  Future<void> _hydrateTokenForRowAtIndex(int index, String validId) async {
    final token = await widget.loadClientToken(validId);
    if (!mounted) {
      return;
    }
    if (index >= _rows.length) {
      return;
    }
    if (_rows[index].agentId.text.trim() != validId) {
      return;
    }
    if (token != null && token.isNotEmpty) {
      _rows[index].clientToken.text = token;
    }
    _hydratedTokenForAgentId.add(validId);
    setState(() {});
  }

  void _onAgentIdFieldChanged(int index, String newText) {
    if (_validationMessage != null || _inputNoteMessage != null) {
      setState(() {
        _validationMessage = null;
        _inputNoteMessage = null;
      });
    }
    widget.onClearMessages();

    final t = newText.trim();
    while (_committedValidUuidPerRow.length < _rows.length) {
      _committedValidUuidPerRow.add(null);
    }
    while (_committedValidUuidPerRow.length > _rows.length) {
      _committedValidUuidPerRow.removeLast();
    }

    if (isValidClientAgentId(t)) {
      final prev = index < _committedValidUuidPerRow.length
          ? _committedValidUuidPerRow[index]
          : null;
      if (prev != t) {
        _committedValidUuidPerRow[index] = t;
        if (prev != null) {
          _hydratedTokenForAgentId.remove(prev);
        }
        _rows[index].clientToken.clear();
        setState(() {});
        unawaited(_hydrateTokenForRowAtIndex(index, t));
      }
    } else if (t.isEmpty) {
      if (index < _committedValidUuidPerRow.length) {
        final prev = _committedValidUuidPerRow[index];
        if (prev != null) {
          _hydratedTokenForAgentId.remove(prev);
        }
        _committedValidUuidPerRow[index] = null;
      }
      _rows[index].clientToken.clear();
      setState(() {});
    }

    _notifyDraftSlotsChanged();
    _cancelPersistTimerForRow(index);
    _schedulePersistTokenForRow(index);
  }

  void _addRow() {
    setState(() {
      _rows = <_RowControllers>[
        ..._rows,
        _RowControllers(
          agentId: TextEditingController(),
          clientToken: TextEditingController(),
        ),
      ];
      _obscureToken.add(true);
      _committedValidUuidPerRow.add(null);
    });
    _notifyDraftSlotsChanged();
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) {
      return;
    }
    _cancelAllPersistTimers();
    setState(() {
      final removed = _rows[index];
      removed.agentId.dispose();
      removed.clientToken.dispose();
      _rows = List<_RowControllers>.from(_rows)..removeAt(index);
      _obscureToken.removeAt(index);
      _committedValidUuidPerRow.removeAt(index);
    });
    _notifyDraftSlotsChanged();
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
        SizedBox(height: tokens.gapSm),
        Text(l10n.clientAgentsRequestAccessIntroToken),
        SizedBox(height: tokens.gapMd),
        for (var i = 0; i < _rows.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: tokens.gapMd),
          _RequestAccessRow(
            index: i,
            row: _rows[i],
            l10n: l10n,
            tokens: tokens,
            obscureToken: i >= _obscureToken.length || _obscureToken[i],
            onToggleObscure: () {
              setState(() {
                if (i < _obscureToken.length) {
                  _obscureToken[i] = !_obscureToken[i];
                }
              });
            },
            onAgentIdChanged: (value) => _onAgentIdFieldChanged(i, value),
            onTokenChanged: (_) {
              if (_validationMessage != null) {
                setState(() {
                  _validationMessage = null;
                });
              }
              widget.onClearMessages();
              _schedulePersistTokenForRow(i);
            },
            onFieldSubmitted: () {
              unawaited(
                widget.persistClientTokenDraftLine(
                  agentIdRaw: _rows[i].agentId.text,
                  clientTokenRaw: _rows[i].clientToken.text,
                ),
              );
            },
            canRemove: _rows.length > 1,
            onRemove: () => _removeRow(i),
          ),
        ],
        SizedBox(height: tokens.gapSm),
        Align(
          alignment: Alignment.centerLeft,
          child: AppSecondaryButton(
            label: l10n.clientAgentsRequestAccessAddRow,
            icon: const Icon(Icons.add_rounded),
            onPressed: widget.isMutating ? null : _addRow,
          ),
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
    final rows = _rows
        .map(
          (r) => ClientAgentAccessRequestRowInput(
            agentIdRaw: r.agentId.text,
            clientTokenRaw: r.clientToken.text,
          ),
        )
        .toList(growable: false);

    final parsed = _parseRows(rows, l10n);
    if (parsed == null) {
      return;
    }

    final accepted = await widget.onSubmitRows(parsed.rows);
    if (!mounted) {
      return;
    }

    if (accepted) {
      _cancelAllPersistTimers();
      setState(() {
        _disposeRowControllers();
        _rows = _createRowsFromSlots(const <String>['']);
        _hydratedTokenForAgentId.clear();
        _syncCommittedValidUuidsFromControllers();
        _syncObscureFlags();
      });
      widget.onDraftSlotsChanged(const <String>['']);
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

  _ParsedRowsResult? _parseRows(
    List<ClientAgentAccessRequestRowInput> rows,
    AppLocalizations l10n,
  ) {
    final validAgentIds = <String>{};
    final duplicatedAgentIds = <String>{};
    final invalidAgentIds = <String>[];

    for (final row in rows) {
      final raw = row.agentIdRaw.trim();
      if (raw.isEmpty) {
        continue;
      }
      if (!isValidClientAgentId(raw)) {
        invalidAgentIds.add(raw);
        continue;
      }
      if (!validAgentIds.add(raw)) {
        duplicatedAgentIds.add(raw);
      }
    }

    if (validAgentIds.isEmpty) {
      setState(() {
        _validationMessage = invalidAgentIds.isEmpty
            ? l10n.clientAgentsValidationNeedOneValidId
            : l10n.clientAgentsValidationInvalidIds(
                invalidAgentIds.join(', '),
              );
        _inputNoteMessage = null;
      });
      return null;
    }

    if (invalidAgentIds.isNotEmpty) {
      setState(() {
        _validationMessage = l10n.clientAgentsValidationInvalidIds(
          invalidAgentIds.join(', '),
        );
        _inputNoteMessage = null;
      });
      return null;
    }

    final dedupedRows = <ClientAgentAccessRequestRowInput>[];
    final seen = <String>{};
    for (final row in rows) {
      final id = row.agentIdRaw.trim();
      if (!isValidClientAgentId(id)) {
        continue;
      }
      if (seen.add(id)) {
        dedupedRows.add(row);
      }
    }

    return _ParsedRowsResult(
      rows: dedupedRows,
      duplicatedAgentIds: duplicatedAgentIds,
    );
  }
}

class _ParsedRowsResult {
  const _ParsedRowsResult({
    required this.rows,
    required this.duplicatedAgentIds,
  });

  final List<ClientAgentAccessRequestRowInput> rows;
  final Set<String> duplicatedAgentIds;
}

class _RequestAccessRow extends StatelessWidget {
  const _RequestAccessRow({
    required this.index,
    required this.row,
    required this.l10n,
    required this.tokens,
    required this.obscureToken,
    required this.onToggleObscure,
    required this.onAgentIdChanged,
    required this.onTokenChanged,
    required this.onFieldSubmitted,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _RowControllers row;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final bool obscureToken;
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
            controller: row.agentId,
            label: l10n.clientAgentsAgentIdsLabel,
            hintText: '11111111-1111-1111-1111-111111111111',
            textInputAction: TextInputAction.next,
            onChanged: onAgentIdChanged,
            onFieldSubmitted: (_) => onFieldSubmitted(),
          ),
          SizedBox(height: tokens.gapSm),
          AppTextField(
            controller: row.clientToken,
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
