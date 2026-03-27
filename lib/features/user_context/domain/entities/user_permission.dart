enum UserPermission {
  viewReports(
    label: 'Relatorios gerenciais',
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
