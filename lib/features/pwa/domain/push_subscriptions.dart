abstract interface class PushSubscriptions {
  Future<void> enable(String user);
  Future<void> disable(String user);
  Future<void> reconcile(String user);
}

/// Native applications do not register browser push subscriptions.
class InactivePushSubscriptions implements PushSubscriptions {
  @override
  Future<void> enable(String user) async {}
  @override
  Future<void> disable(String user) async {}
  @override
  Future<void> reconcile(String user) async {}
}
