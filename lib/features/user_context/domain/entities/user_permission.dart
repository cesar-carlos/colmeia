enum UserPermission {
  viewReports(
    label: 'Relatórios gerenciais',
  ),
  viewDashboard(
    label: 'Dashboard principal',
  )
  ;

  const UserPermission({
    required this.label,
  });

  final String label;
}
