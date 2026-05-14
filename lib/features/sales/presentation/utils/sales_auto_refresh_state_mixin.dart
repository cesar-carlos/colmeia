import 'dart:async';

import 'package:colmeia/app/router/app_shell_route_observer.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_control.dart';
import 'package:flutter/material.dart';

mixin SalesAutoRefreshStateMixin<T extends StatefulWidget> on State<T> {
  late final _SalesAutoRefreshAppLifecycleObserver
  _salesAutoRefreshAppLifecycleObserver;
  late final _SalesAutoRefreshRouteAware _salesAutoRefreshRouteAware;
  Timer? _salesAutoRefreshTimer;
  SalesAutoRefreshInterval? _salesAutoRefreshInterval;
  DateTime? _salesAutoRefreshLastUpdatedAt;
  int _salesAutoRefreshActiveReloads = 0;
  bool _salesAutoRefreshAppVisible = true;
  bool _salesAutoRefreshRouteVisible = true;
  bool _salesAutoRefreshRouteObserverSubscribed = false;

  SalesAutoRefreshInterval? get salesAutoRefreshInterval =>
      _salesAutoRefreshInterval;

  DateTime? get salesAutoRefreshLastUpdatedAt => _salesAutoRefreshLastUpdatedAt;

  @protected
  bool get canScheduleSalesAutoRefresh => true;

  @protected
  Future<void> performSalesAutoRefreshReload();

  @override
  void initState() {
    super.initState();
    _salesAutoRefreshAppLifecycleObserver =
        _SalesAutoRefreshAppLifecycleObserver(
          onVisibilityChanged: _setSalesAutoRefreshAppVisibility,
        );
    _salesAutoRefreshRouteAware = _SalesAutoRefreshRouteAware(
      onVisibilityChanged: _setSalesAutoRefreshRouteVisibility,
    );
    WidgetsBinding.instance.addObserver(_salesAutoRefreshAppLifecycleObserver);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_salesAutoRefreshRouteObserverSubscribed) {
      return;
    }
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) {
      appShellRouteObserver.subscribe(_salesAutoRefreshRouteAware, route);
      _salesAutoRefreshRouteObserverSubscribed = true;
    }
  }

  @protected
  Future<void> reloadWithSalesAutoRefresh({bool force = false}) async {
    if (!force && _salesAutoRefreshActiveReloads > 0) {
      return;
    }
    _cancelSalesAutoRefreshTimer();
    try {
      await _trackSalesAutoRefreshReload(performSalesAutoRefreshReload);
    } finally {
      _scheduleSalesAutoRefreshTimer();
    }
  }

  @protected
  void disableSalesAutoRefresh() {
    _cancelSalesAutoRefreshTimer();
    if (_salesAutoRefreshInterval == null) {
      return;
    }
    if (!mounted) {
      _salesAutoRefreshInterval = null;
      return;
    }
    setState(() {
      _salesAutoRefreshInterval = null;
    });
  }

  @protected
  void setSalesAutoRefreshInterval(SalesAutoRefreshInterval? interval) {
    if (_salesAutoRefreshInterval == interval) {
      return;
    }
    setState(() {
      _salesAutoRefreshInterval = interval;
    });
    _restartSalesAutoRefreshTimer();
  }

  void _setSalesAutoRefreshAppVisibility(bool visible) {
    if (_salesAutoRefreshAppVisible == visible) {
      return;
    }
    _salesAutoRefreshAppVisible = visible;
    _syncSalesAutoRefreshTimerWithVisibility();
  }

  void _setSalesAutoRefreshRouteVisibility(bool visible) {
    if (_salesAutoRefreshRouteVisible == visible) {
      return;
    }
    _salesAutoRefreshRouteVisible = visible;
    _syncSalesAutoRefreshTimerWithVisibility();
  }

  void _syncSalesAutoRefreshTimerWithVisibility() {
    if (_canRunSalesAutoRefreshTimer) {
      _scheduleSalesAutoRefreshTimer();
    } else {
      _cancelSalesAutoRefreshTimer();
    }
  }

  Future<void> _handleSalesAutoRefreshTick() async {
    if (!mounted) {
      return;
    }
    if (!_canRunSalesAutoRefreshTimer || _salesAutoRefreshActiveReloads > 0) {
      _scheduleSalesAutoRefreshTimer();
      return;
    }

    try {
      await _trackSalesAutoRefreshReload(performSalesAutoRefreshReload);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'sales auto refresh',
        ),
      );
    } finally {
      _scheduleSalesAutoRefreshTimer();
    }
  }

  Future<void> _trackSalesAutoRefreshReload(
    Future<void> Function() reload,
  ) async {
    _salesAutoRefreshActiveReloads += 1;
    try {
      await reload();
      if (mounted) {
        setState(() {
          _salesAutoRefreshLastUpdatedAt = DateTime.now();
        });
      }
    } finally {
      _salesAutoRefreshActiveReloads -= 1;
    }
  }

  void _restartSalesAutoRefreshTimer() {
    _cancelSalesAutoRefreshTimer();
    _scheduleSalesAutoRefreshTimer();
  }

  bool get _canRunSalesAutoRefreshTimer =>
      mounted &&
      _salesAutoRefreshAppVisible &&
      _salesAutoRefreshRouteVisible &&
      canScheduleSalesAutoRefresh;

  void _scheduleSalesAutoRefreshTimer() {
    _cancelSalesAutoRefreshTimer();
    final interval = _salesAutoRefreshInterval;
    if (interval == null || !_canRunSalesAutoRefreshTimer) {
      return;
    }
    _salesAutoRefreshTimer = Timer(interval.duration, () {
      unawaited(_handleSalesAutoRefreshTick());
    });
  }

  void _cancelSalesAutoRefreshTimer() {
    _salesAutoRefreshTimer?.cancel();
    _salesAutoRefreshTimer = null;
  }

  @override
  void dispose() {
    if (_salesAutoRefreshRouteObserverSubscribed) {
      appShellRouteObserver.unsubscribe(_salesAutoRefreshRouteAware);
    }
    WidgetsBinding.instance.removeObserver(
      _salesAutoRefreshAppLifecycleObserver,
    );
    _cancelSalesAutoRefreshTimer();
    super.dispose();
  }
}

class _SalesAutoRefreshAppLifecycleObserver extends WidgetsBindingObserver {
  _SalesAutoRefreshAppLifecycleObserver({required this.onVisibilityChanged});

  final ValueChanged<bool> onVisibilityChanged;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final visible = switch (state) {
      AppLifecycleState.resumed => true,
      AppLifecycleState.inactive ||
      AppLifecycleState.hidden ||
      AppLifecycleState.paused ||
      AppLifecycleState.detached => false,
    };
    onVisibilityChanged(visible);
  }
}

class _SalesAutoRefreshRouteAware extends RouteAware {
  _SalesAutoRefreshRouteAware({required this.onVisibilityChanged});

  final ValueChanged<bool> onVisibilityChanged;

  @override
  void didPush() => onVisibilityChanged(true);

  @override
  void didPopNext() => onVisibilityChanged(true);

  @override
  void didPushNext() => onVisibilityChanged(false);

  @override
  void didPop() => onVisibilityChanged(false);
}
