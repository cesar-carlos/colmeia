import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_constraints.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agent_access_request_row_input.dart';
import 'package:colmeia/features/client_agents/presentation/utils/client_agent_id_format.dart';
import 'package:flutter/foundation.dart';

/// Outcome of parsing the rows from the "request access" form.
///
/// Modeled as a sealed type so the UI can switch over the structured
/// reason instead of inspecting strings or relying on null checks.
@immutable
sealed class ClientAgentsRequestAccessFormParseResult {
  const ClientAgentsRequestAccessFormParseResult();
}

/// Returned when at least one row holds a valid UUID and there are no
/// blocking validation errors.
///
/// [rows] preserves the original order of [parseClientAgentsRequestAccessForm]
/// input but only keeps the first occurrence of each valid agent id.
/// [duplicatedAgentIds] reports any id that appeared more than once so the
/// caller can show a soft note after a successful submit.
@immutable
class ClientAgentsRequestAccessFormParseSuccess
    extends ClientAgentsRequestAccessFormParseResult {
  const ClientAgentsRequestAccessFormParseSuccess({
    required this.rows,
    required this.duplicatedAgentIds,
  });

  final List<ClientAgentAccessRequestRowInput> rows;
  final Set<String> duplicatedAgentIds;
}

/// Returned when there is no usable row to submit and the form already
/// holds invalid input — caller should keep the submit button enabled but
/// show a validation message.
@immutable
sealed class ClientAgentsRequestAccessFormParseFailure
    extends ClientAgentsRequestAccessFormParseResult {
  const ClientAgentsRequestAccessFormParseFailure();
}

/// No row contributed a valid UUID and the user did not even type an
/// invalid one — the form is effectively empty.
class ClientAgentsRequestAccessFormNeedsAtLeastOneId
    extends ClientAgentsRequestAccessFormParseFailure {
  const ClientAgentsRequestAccessFormNeedsAtLeastOneId();
}

/// At least one row carries an invalid UUID. Holds the offending raw ids
/// so the caller can render a precise error message.
class ClientAgentsRequestAccessFormHasInvalidIds
    extends ClientAgentsRequestAccessFormParseFailure {
  const ClientAgentsRequestAccessFormHasInvalidIds(this.invalidAgentIds);

  final List<String> invalidAgentIds;
}

/// At least one row has a token exceeding
/// [ClientAgentTokenConstraints.maxLength]. Holds the affected agent ids.
class ClientAgentsRequestAccessFormHasTokensTooLong
    extends ClientAgentsRequestAccessFormParseFailure {
  const ClientAgentsRequestAccessFormHasTokensTooLong({
    required this.maxLength,
    required this.agentIds,
  });

  final int maxLength;
  final List<String> agentIds;
}

/// Pure parser for the "request access" form rows.
///
/// Trims and validates each agent id; tracks duplicates; enforces the
/// token length limit. Empty rows are ignored, never treated as invalid,
/// so the user can keep extra blank rows around without blocking submit.
///
/// The function intentionally returns a structured result instead of
/// throwing or returning `null`, so the widget can render the right
/// message and remain trivially testable from pure Dart tests.
ClientAgentsRequestAccessFormParseResult parseClientAgentsRequestAccessForm(
  List<ClientAgentAccessRequestRowInput> rows,
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
    if (invalidAgentIds.isEmpty) {
      return const ClientAgentsRequestAccessFormNeedsAtLeastOneId();
    }
    return ClientAgentsRequestAccessFormHasInvalidIds(invalidAgentIds);
  }

  if (invalidAgentIds.isNotEmpty) {
    return ClientAgentsRequestAccessFormHasInvalidIds(invalidAgentIds);
  }

  if (tokensTooLong.isNotEmpty) {
    return ClientAgentsRequestAccessFormHasTokensTooLong(
      maxLength: ClientAgentTokenConstraints.maxLength,
      agentIds: tokensTooLong,
    );
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

  return ClientAgentsRequestAccessFormParseSuccess(
    rows: dedupedRows,
    duplicatedAgentIds: duplicatedAgentIds,
  );
}
