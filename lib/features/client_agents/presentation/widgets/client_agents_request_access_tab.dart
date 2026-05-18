import 'dart:async';

import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_constraints.dart';
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
    this.retryAfterSeconds,
  });

  final List<String> initialAgentIdSlots;

  final Future<bool> Function(List<ClientAgentAccessRequestRowInput> rows)
  onSubmitRows;
  final VoidCallback onClearMessages;

  /// `true` when the controller is currently sending the request OR
  /// the cool-down armed by a server `Retry-After` is still open.
  /// Either case must keep the submit button disabled.
  final bool isMutating;

  /// Remaining seconds in the request-access cool-down window, or
  /// `null` when no `Retry-After` is currently in effect. When set,
  /// the submit CTA renders a "Try again in Ns" countdown instead of
  /// the regular label so the user understands why the action is
  /// blocked. Mirrors the UX already wired on the sync button.
  final int? retryAfterSeconds;
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

/// Mutable state for a single request-access row. Each row carries a stable
/// `identity` used as both Flutter widget `Key` and the timer/hydration map
/// key, so removing or reordering rows never causes timers, hydration tasks
/// or focus to land on the wrong line.
class _RowControllers {
  _RowControllers({
    required this.identity,
    required this.agentId,
    required this.clientToken,
  });

  final Object identity;
  final TextEditingController agentId;
  final TextEditingController clientToken;

  /// Last valid UUID committed for this row, or `null` while the field holds
  /// an invalid or empty value. Used to detect "id changed to a new valid
  /// UUID" transitions for hydration.
  String? committedValidUuid;

  /// True while `_hydrateTokenForRow` is in flight. While hydrating, the
  /// debounced `persistClientTokenDraftLine` timer is suppressed so we never
  /// race-overwrite a non-empty stored token with the empty value the
  /// controller carries during hydration.
  bool isHydratingToken = false;

  bool obscureToken = true;
}

class _ClientAgentsRequestAccessTabState
    extends State<ClientAgentsRequestAccessTab> {
  late List<_RowControllers> _rows;

  /// Persist debounce timers keyed by row identity (not index) so middle-row
  /// removals never affect unrelated timers and reordering never reuses the
  /// wrong row's timer.
  final Map<Object, Timer> _persistTimersByRow = <Object, Timer>{};

  /// Hydration cache for "we already asked the store about this id". The
  /// value is the resolved token (or `null` for "no token currently stored");
  /// used so re-typing the same id in a new row reuses the previous answer
  /// instead of round-tripping again.
  final Map<String, String?> _hydratedTokenByAgentId = <String, String?>{};

  String? _validationMessage;
  String? _inputNoteMessage;
  int _nextRowIdentitySeed = 0;

  static const Duration _persistDebounce = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _rows = _createRowsFromSlots(widget.initialAgentIdSlots);
    unawaited(_hydrateAllRowsThatHaveAValidId());
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
      _hydratedTokenByAgentId.clear();
      unawaited(_hydrateAllRowsThatHaveAValidId());
    }
  }

  @override
  void dispose() {
    _cancelAllPersistTimers();
    _disposeRowControllers();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Row construction
  // ---------------------------------------------------------------------------

  Object _allocateRowIdentity() {
    final id = _nextRowIdentitySeed;
    _nextRowIdentitySeed++;
    return Object.hashAll(<Object>['client_agents_request_access_row', id]);
  }

  List<_RowControllers> _createRowsFromSlots(List<String> slots) {
    final raw = slots.isEmpty ? <String>[''] : List<String>.from(slots);
    return raw
        .map((slot) {
          final controllers = _RowControllers(
            identity: _allocateRowIdentity(),
            agentId: TextEditingController(text: slot),
            clientToken: TextEditingController(),
          );
          final id = slot.trim();
          if (isValidClientAgentId(id)) {
            controllers.committedValidUuid = id;
          }
          return controllers;
        })
        .toList(growable: false);
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

  // ---------------------------------------------------------------------------
  // Persistence (debounced)
  // ---------------------------------------------------------------------------

  void _cancelPersistTimerForRow(_RowControllers row) {
    _persistTimersByRow.remove(row.identity)?.cancel();
  }

  void _cancelAllPersistTimers() {
    for (final timer in _persistTimersByRow.values) {
      timer.cancel();
    }
    _persistTimersByRow.clear();
  }

  /// Schedules a debounced persistence call for [row]. The call is suppressed
  /// while [_hydrateTokenForRow] is in flight to avoid the destructive race
  /// where the empty string the controller holds during hydration is
  /// persisted before the secure-storage read returns.
  void _schedulePersistTokenForRow(_RowControllers row) {
    _cancelPersistTimerForRow(row);
    _persistTimersByRow[row.identity] = Timer(_persistDebounce, () async {
      _persistTimersByRow.remove(row.identity);
      if (!_rows.contains(row)) {
        return;
      }
      if (row.isHydratingToken) {
        return;
      }
      await widget.persistClientTokenDraftLine(
        agentIdRaw: row.agentId.text,
        clientTokenRaw: row.clientToken.text,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Hydration
  // ---------------------------------------------------------------------------

  Future<void> _hydrateAllRowsThatHaveAValidId() async {
    final initialRows = List<_RowControllers>.from(_rows);
    await Future.wait(
      initialRows.map((row) async {
        final id = row.agentId.text.trim();
        if (!isValidClientAgentId(id)) {
          return;
        }
        await _hydrateTokenForRow(row, id);
      }),
    );
  }

  /// Loads the stored token for [validId] and writes it into [row]'s token
  /// field — but only when it is still safe to do so:
  /// - the row is still part of [_rows];
  /// - the row's id field still holds [validId] (user may have typed
  ///   something else while we were awaiting);
  /// - the user has not started typing a different token (we never overwrite
  ///   user input).
  Future<void> _hydrateTokenForRow(_RowControllers row, String validId) async {
    if (row.isHydratingToken) {
      return;
    }
    row.isHydratingToken = true;
    // Cancel any debounced persist that would race with the read below.
    _cancelPersistTimerForRow(row);

    String? resolved;
    final cached = _hydratedTokenByAgentId[validId];
    if (_hydratedTokenByAgentId.containsKey(validId)) {
      resolved = cached;
    } else {
      try {
        resolved = await widget.loadClientToken(validId);
      } finally {
        if (mounted) {
          _hydratedTokenByAgentId[validId] = resolved;
        }
      }
    }

    if (!mounted) {
      row.isHydratingToken = false;
      return;
    }
    if (!_rows.contains(row)) {
      row.isHydratingToken = false;
      return;
    }
    if (row.agentId.text.trim() != validId) {
      row.isHydratingToken = false;
      return;
    }

    final currentTokenInField = row.clientToken.text;
    if (resolved != null && resolved.isNotEmpty) {
      // Only overwrite when the field is empty — never clobber the user's
      // own typing.
      if (currentTokenInField.isEmpty) {
        row.clientToken.text = resolved;
        setState(() {});
      }
    }
    row.isHydratingToken = false;
  }

  // ---------------------------------------------------------------------------
  // Field change handlers
  // ---------------------------------------------------------------------------

  void _onAgentIdFieldChanged(_RowControllers row, String newText) {
    if (_validationMessage != null || _inputNoteMessage != null) {
      setState(() {
        _validationMessage = null;
        _inputNoteMessage = null;
      });
    }
    widget.onClearMessages();

    final trimmed = newText.trim();

    if (isValidClientAgentId(trimmed)) {
      final previous = row.committedValidUuid;
      if (previous != trimmed) {
        row.committedValidUuid = trimmed;
        // Drop the cached hydration of the *previous* id from this row so
        // re-typing it later forces a fresh read (the user may have edited
        // its token elsewhere in the app).
        if (previous != null) {
          _hydratedTokenByAgentId.remove(previous);
        }
        // The token field belongs to the previous id; clear it before we
        // try to hydrate the new id's token.
        row.clientToken.clear();
        setState(() {});
        unawaited(_hydrateTokenForRow(row, trimmed));
      }
    } else if (trimmed.isEmpty) {
      final previous = row.committedValidUuid;
      if (previous != null) {
        _hydratedTokenByAgentId.remove(previous);
      }
      row.committedValidUuid = null;
      row.clientToken.clear();
      setState(() {});
    } else {
      // Invalid (partial) UUID. Keep `committedValidUuid` pointing at the
      // last good value so a typo + correction back to the same UUID does
      // not silently skip the hydration check above.
    }

    _notifyDraftSlotsChanged();
    _schedulePersistTokenForRow(row);
  }

  void _onTokenFieldChanged(_RowControllers row) {
    if (_validationMessage != null) {
      setState(() {
        _validationMessage = null;
      });
    }
    widget.onClearMessages();
    _schedulePersistTokenForRow(row);
  }

  void _addRow() {
    setState(() {
      _rows = <_RowControllers>[
        ..._rows,
        _RowControllers(
          identity: _allocateRowIdentity(),
          agentId: TextEditingController(),
          clientToken: TextEditingController(),
        ),
      ];
    });
    _notifyDraftSlotsChanged();
  }

  void _removeRow(_RowControllers row) {
    if (_rows.length <= 1) {
      return;
    }
    _cancelPersistTimerForRow(row);
    final removedId = row.committedValidUuid;
    if (removedId != null) {
      _hydratedTokenByAgentId.remove(removedId);
    }
    setState(() {
      row.agentId.dispose();
      row.clientToken.dispose();
      _rows = List<_RowControllers>.from(_rows)..remove(row);
    });
    _notifyDraftSlotsChanged();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
            key: ValueKey<Object>(_rows[i].identity),
            index: i,
            row: _rows[i],
            l10n: l10n,
            tokens: tokens,
            onToggleObscure: () {
              setState(() {
                _rows[i].obscureToken = !_rows[i].obscureToken;
              });
            },
            onAgentIdChanged: (value) =>
                _onAgentIdFieldChanged(_rows[i], value),
            onTokenChanged: (_) => _onTokenFieldChanged(_rows[i]),
            onFieldSubmitted: () {
              unawaited(
                widget.persistClientTokenDraftLine(
                  agentIdRaw: _rows[i].agentId.text,
                  clientTokenRaw: _rows[i].clientToken.text,
                ),
              );
            },
            canRemove: _rows.length > 1,
            onRemove: () => _removeRow(_rows[i]),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          // Mirrors the sync button's countdown UX: when the
          // controller has armed `_requestAccessRetryAfterGate` from
          // a server `Retry-After`, swap the CTA label to
          // "Try again in Ns" so the user sees WHY the button is
          // disabled instead of getting silent deadness.
          label: widget.retryAfterSeconds != null
              ? l10n.clientAgentsRequestAccessRetryAfterCountdown(
                  widget.retryAfterSeconds!,
                )
              : l10n.clientAgentsRequestAccessCta,
          icon: const Icon(Icons.send_rounded),
          isLoading: widget.isMutating && widget.retryAfterSeconds == null,
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
        _hydratedTokenByAgentId.clear();
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
    final tokensTooLong = <String>[];

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
      final token = row.clientTokenRaw.trim();
      if (token.length > ClientAgentTokenConstraints.maxLength) {
        tokensTooLong.add(raw);
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

    if (tokensTooLong.isNotEmpty) {
      setState(() {
        _validationMessage = l10n.clientAgentsValidationTokenTooLong(
          ClientAgentTokenConstraints.maxLength,
          tokensTooLong.join(', '),
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
    required this.onToggleObscure,
    required this.onAgentIdChanged,
    required this.onTokenChanged,
    required this.onFieldSubmitted,
    required this.canRemove,
    required this.onRemove,
    super.key,
  });

  final int index;
  final _RowControllers row;
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
            obscureText: row.obscureToken,
            textInputAction: TextInputAction.done,
            onChanged: onTokenChanged,
            onFieldSubmitted: (_) => onFieldSubmitted(),
            suffix: IconButton(
              tooltip: row.obscureToken
                  ? l10n.clientAgentsClientTokenShow
                  : l10n.clientAgentsClientTokenHide,
              onPressed: onToggleObscure,
              icon: Icon(
                row.obscureToken
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
