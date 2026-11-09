enum OfflinePackageIssue {
  connectionRequired,
  cancelled,
  authorizationExpired,
  storageUnavailable,
  incomplete,
}

class OfflinePackageException implements Exception {
  const OfflinePackageException(this.issue);
  final OfflinePackageIssue issue;
}
