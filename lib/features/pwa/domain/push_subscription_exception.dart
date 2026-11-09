enum PushSubscriptionIssue { serverDisabled, permissionDenied, invalidResponse }

class PushSubscriptionException implements Exception {
  const PushSubscriptionException(this.issue);

  final PushSubscriptionIssue issue;
}
