enum UserPermission {
  viewDashboard,
  manageAgents,
}

/// Resolves a permission from an API or storage string. Names that do not match
/// a current enum value return null so payloads can carry forward-looking or
/// legacy values without throwing.
UserPermission? parseUserPermissionName(String name) {
  for (final value in UserPermission.values) {
    if (value.name == name) {
      return value;
    }
  }
  return null;
}

Set<UserPermission> parseUserPermissionNameSet(Iterable<String> names) {
  return names.map(parseUserPermissionName).whereType<UserPermission>().toSet();
}
