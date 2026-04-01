class DashboardAccessGrant {
  const DashboardAccessGrant({
    required this.dashboardId,
    this.allowedFilterKeys = const <String>{},
    this.allowedActions = const <String>{},
  });

  final String dashboardId;
  final Set<String> allowedFilterKeys;
  final Set<String> allowedActions;
}
