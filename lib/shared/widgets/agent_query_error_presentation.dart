import 'package:colmeia/shared/widgets/agent_query_error_panel.dart' show AgentQueryErrorPanel;
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';

/// Immutable view model for [AgentQueryErrorPanel] without feature coupling.
class AgentQueryErrorPresentation {
  const AgentQueryErrorPresentation({
    required this.title,
    required this.message,
    required this.panelTone,
    this.showRetry = true,
    this.showManageAgents = false,
    this.suppressPanel = false,
    this.detailsBody,
  });

  final String title;
  final String message;
  final AppInlinePanelTone panelTone;
  final bool showRetry;
  final bool showManageAgents;
  final bool suppressPanel;
  final String? detailsBody;
}
