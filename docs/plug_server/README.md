# Hub handoffs and archived protocol snapshots

This directory preserves investigations and handoffs to the `plug_server` team.
Their status reflects the investigation date; it does not establish the status
of the current production hub. Current Colmeia transport defaults and routing
belong to the [canonical integration index](../plug_server_docs_index_for_colmeia.md)
and [SQL options](../bridge_agent_sql_api_options.md).

## Investigation records

| Document | Topic |
| --- | --- |
| [Relay timeout investigation](socket_relay_timeout_deep_investigation_2026_07_22.md) | Correlation and missing agent responses |
| [Socket smoke reproduction](relay_request_timeout_socket_smoke_2026_07_22.md) | Reproduction steps and correlation IDs |
| [Relay envelope timeout](relay_envelope_timeout_ms.md) | Per-request timeout handoff |
| [Rejected request correlation](relay_rpc_accepted_error_missing_ids.md) | Missing IDs in error acknowledgments |

## Protocol snapshots

The [relay protocol](socket/socket_relay_protocol.md) and
[client SDK notes](socket/socket_client_sdk.md) are archived copies synchronized
from the hub on 2026-07-22. Keep them for investigation context; do not update
these copies as competing current specifications. References to snippets, ADRs,
and configuration inside them belong to the upstream hub repository.

Server delivery reports and related proposals are indexed in
[server adjustments](../server_adjustments/README.md). Verify hub deployment
status before treating any historical handoff as an outstanding action.
