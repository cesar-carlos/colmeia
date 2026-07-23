import 'dart:async';

enum AuthSessionEventType {
  invalidated,
  sessionRenewed,
}

class AuthSessionEvent {
  const AuthSessionEvent(this.type);

  const AuthSessionEvent.invalidated() : this(AuthSessionEventType.invalidated);

  const AuthSessionEvent.sessionRenewed()
    : this(AuthSessionEventType.sessionRenewed);

  final AuthSessionEventType type;
}

class AuthSessionEvents {
  final StreamController<AuthSessionEvent> _controller =
      StreamController<AuthSessionEvent>.broadcast();

  Stream<AuthSessionEvent> get stream => _controller.stream;

  void notifyInvalidated() {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(const AuthSessionEvent.invalidated());
  }

  void notifySessionRenewed() {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(const AuthSessionEvent.sessionRenewed());
  }

  Future<void> dispose() => _controller.close();
}
