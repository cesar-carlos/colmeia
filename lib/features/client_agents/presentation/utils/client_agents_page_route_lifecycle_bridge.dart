typedef ClientAgentsScreenVisibilitySetter =
    void Function({required bool isVisible});

class ClientAgentsPageRouteLifecycleBridge {
  const ClientAgentsPageRouteLifecycleBridge({
    required ClientAgentsScreenVisibilitySetter setScreenVisible,
  }) : _setScreenVisible = setScreenVisible;

  final ClientAgentsScreenVisibilitySetter _setScreenVisible;

  void didPush() {
    _setScreenVisible(isVisible: true);
  }

  void didPopNext() {
    _setScreenVisible(isVisible: true);
  }

  void didPushNext() {
    _setScreenVisible(isVisible: false);
  }

  void didPop() {
    _setScreenVisible(isVisible: false);
  }
}
