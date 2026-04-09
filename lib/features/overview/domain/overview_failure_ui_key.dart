/// Context field keys for overview load failures; presentation maps them to
/// localized user-visible text.
abstract final class OverviewFailureUiKey {
  static const String field = 'overviewFailureUiKey';

  static const String noApprovedAgents = 'noApprovedAgents';
  static const String loadFailed = 'loadFailed';
  static const String missingLocalClientToken = 'missingLocalClientToken';
}
