class ReportAccessGrant {
  const ReportAccessGrant({
    required this.reportId,
    this.allowedFilterKeys = const <String>{},
    this.allowedActions = const <String>{},
  });

  final String reportId;
  final Set<String> allowedFilterKeys;
  final Set<String> allowedActions;
}
