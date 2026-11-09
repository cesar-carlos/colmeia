import 'dart:async';
import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/pwa/pwa_platform.dart';
import 'package:colmeia/features/agent_queries/application/sync/cache_refresh_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:colmeia/features/client_agents/domain/ports/agent_presence_stream.dart';
import 'package:colmeia/features/pwa/application/pwa_package_service.dart';
import 'package:colmeia/features/pwa/domain/push_subscriptions.dart';
import 'package:flutter/widgets.dart';

class CacheRefreshLifecycle extends StatefulWidget {
  const CacheRefreshLifecycle({
    required this.child,
    required this.auth,
    required this.coordinator,
    required this.presence,
    required this.platform,
    required this.packages,
    required this.push,
    required this.cache,
    required this.lock,
    super.key,
  });
  final Widget child;
  final AuthController auth;
  final CacheRefreshCoordinator coordinator;
  final AgentPresenceStream presence;
  final PwaPlatform platform;
  final PwaPackageService packages;
  final PushSubscriptions push;
  final AppCacheStore cache;
  final CacheRefreshLock lock;
  @override
  State<CacheRefreshLifecycle> createState() => _CacheRefreshLifecycleState();
}

class _CacheRefreshLifecycleState extends State<CacheRefreshLifecycle>
    with WidgetsBindingObserver {
  StreamSubscription<AgentPresenceEvent>? _presence;
  StreamSubscription<String>? _platform;
  Timer? _maintenance;
  bool _maintaining = false;
  bool _pushPending = false;
  String? _user;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.auth.addListener(_session);
    _presence = widget.presence.events().listen(
      (e) => widget.coordinator.presenceChanged(e.agentId, e.observedAt),
    );
    _platform = widget.platform.events.listen((e) {
      if (e == 'online' || e == 'focus' || e == 'colmeia-permissions-changed') {
        _resume();
      }
    });
    _maintenance = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_syncPackages()),
    );
    _session();
  }

  void _session() {
    final user = widget.auth.session?.userId;
    if (user == _user) return;
    final previous = _user;
    _user = user;
    if (previous != null) {
      widget.coordinator.stop();
      unawaited(
        widget.coordinator.repository.clearUser(previous).catchError((
          Object e,
          StackTrace s,
        ) {
          AppLogger.warning(
            'cache.refresh.logout_cleanup_failed',
            error: e,
            stackTrace: s,
          );
        }),
      );
    }
    if (user != null) {
      widget.coordinator.start(user);
      _resume();
    }
  }

  void _resume() {
    widget.coordinator.resume();
    unawaited(_syncPackages());
    unawaited(_reconcilePush());
  }

  Future<void> _reconcilePush() async {
    final user = _user;
    if (user == null || _pushPending || !widget.platform.online) return;
    _pushPending = true;
    try {
      await widget.push.reconcile(user);
    } on Object catch (e, s) {
      AppLogger.warning(
        'cache.refresh.push_reconcile_failed',
        error: e,
        stackTrace: s,
      );
    } finally {
      _pushPending = false;
    }
  }

  Future<void> _syncPackages() async {
    final user = _user;
    if (user == null || _maintaining || !widget.platform.supported) return;
    _maintaining = true;
    try {
      await widget.lock.run('package-enrollment-$user', () async {
        final selected = await widget.packages.selectedAgents(user);
        final key = 'pwa/scheduled/${Uri.encodeComponent(user)}';
        final raw = await widget.cache.getString(key);
        final previous = raw == null
            ? <String>[]
            : (jsonDecode(raw) as List).cast<String>();
        if (!mounted || user != _user) return;
        for (final agent in previous.where((a) => !selected.contains(a))) {
          widget.coordinator.cancel('offline-$agent');
          await widget.coordinator.repository.remove(user, 'offline-$agent');
        }
        for (final agent in selected.where((a) => !previous.contains(a))) {
          if (!mounted || user != _user) return;
          await widget.coordinator.repository.save(
            CacheRefreshSchedule(
              id: 'offline-$agent',
              userId: user,
              agentId: agent,
              reportId: 'offlinePackage',
            ),
          );
        }
        if (!mounted || user != _user) return;
        await widget.cache.putString(key: key, value: jsonEncode(selected));
      });
      await widget.coordinator.tick();
    } on Object catch (e, s) {
      AppLogger.warning(
        'cache.refresh.package_enrollment_failed',
        error: e,
        stackTrace: s,
      );
    } finally {
      _maintaining = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _resume();
  }

  @override
  void dispose() {
    _maintenance?.cancel();
    unawaited(_presence?.cancel());
    unawaited(_platform?.cancel());
    widget.auth.removeListener(_session);
    widget.coordinator.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
