/// Context field keys for overview load failures; presentation maps them to
/// localized user-visible text.
///
/// Note: the "missing client token" condition is surfaced through the
/// `Overview` entity itself (`requiresClientTokenSetup` /
/// `hasMissingClientToken`) and rendered by
/// `OverviewHomeAlertsSection` instead of via this enum — the
/// repository never produced a failure carrying that key, so it was
/// removed to avoid the ambiguity of having two surfaces for the same
/// state.
abstract final class OverviewFailureUiKey {
  static const String field = 'overviewFailureUiKey';

  static const String noApprovedAgents = 'noApprovedAgents';
  static const String loadFailed = 'loadFailed';
}
