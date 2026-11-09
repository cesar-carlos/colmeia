import 'dart:async';

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/core/pwa/pwa_platform.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/pwa/application/pwa_package_service.dart';
import 'package:flutter/material.dart';

class PwaStatusHost extends StatefulWidget {
  const PwaStatusHost({required this.child, super.key});
  final Widget child;
  @override
  State<PwaStatusHost> createState() => _PwaStatusHostState();
}

class _PwaStatusHostState extends State<PwaStatusHost> {
  StreamSubscription<String>? _events;
  Timer? _timer;
  Timer? _expiry;
  bool _updateAvailable = false;
  bool _refreshing = false;
  bool _refreshAgain = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    if (!getIt.isRegistered<PwaPlatform>()) return;
    _updateAvailable = getIt<PwaPlatform>().updateAvailable;
    _events = getIt<PwaPlatform>().events.listen(_onEvent);
    getIt<AuthController>().addListener(_sessionChanged);
    unawaited(_refresh());
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_refresh()),
    );
  }

  void _sessionChanged() {
    unawaited(_refresh());
  }

  void _onEvent(String event) {
    if (event == 'logout') {
      getIt<PwaPackageService>().invalidateSession();
      getIt<AuthSessionEvents>().notifyInvalidated();
    }
    if (event == 'colmeia-update-available') _updateAvailable = true;
    if (event == 'colmeia-update-busy') {
      _message = 'Conclua as operações nas outras abas antes de atualizar.';
    }
    if (event == 'colmeia-pwa-install-failed') {
      _message = 'Não foi possível preparar o aplicativo para abrir offline.';
    }
    if (mounted) setState(() {});
    if (event == 'online' ||
        event == 'offline' ||
        event == 'focus' ||
        event == 'colmeia-permissions-changed') {
      unawaited(
        _refresh(
          force: event == 'online' || event == 'colmeia-permissions-changed',
        ),
      );
    }
  }

  Future<void> _refresh({bool force = false}) async {
    if (!getIt<PwaPlatform>().supported || !mounted) return;
    if (_refreshing) {
      _refreshAgain = _refreshAgain || force;
      return;
    }
    final user = getIt<AuthController>().session?.userId;
    if (user == null) return;
    _refreshing = true;
    try {
      final packages = getIt<PwaPackageService>();
      final selected = await packages.selectedAgents(user);
      _expiry?.cancel();
      DateTime? earliest;
      for (final agent in selected) {
        final current = await packages.read(user, agent);
        final expiration = current?.authorization.expiresAt;
        if (expiration != null &&
            (earliest == null || expiration.isBefore(earliest))) {
          earliest = expiration;
        }
      }
      if (earliest != null) {
        final remaining = earliest.difference(DateTime.now().toUtc());
        _expiry = Timer(remaining.isNegative ? Duration.zero : remaining, () {
          if (!packages.platform.online) {
            getIt<AuthSessionEvents>().notifyInvalidated();
          }
          unawaited(_refresh());
        });
      }
      if (!packages.platform.online) {
        if (!await packages.canRestoreOffline(user)) {
          getIt<AuthSessionEvents>().notifyInvalidated();
        }
        return;
      }
    } on Object {
      AppLogger.warning(
        'PWA background synchronization failed; previous package retained',
      );
    } finally {
      _refreshing = false;
      if (_refreshAgain && mounted) {
        _refreshAgain = false;
        unawaited(_refresh(force: true));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _expiry?.cancel();
    if (getIt.isRegistered<AuthController>()) {
      getIt<AuthController>().removeListener(_sessionChanged);
    }
    unawaited(_events?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<PwaPlatform>()) return widget.child;
    final platform = getIt<PwaPlatform>();
    final showStatus = !platform.online || _updateAvailable || _message != null;
    return Column(
      children: [
        if (showStatus)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  children: [
                    Text(
                      _message ??
                          (!platform.online
                              ? 'Sem conexão • Dados locais dos últimos 30 dias; o dia atual pode estar parcial.'
                              : 'Atualização disponível'),
                    ),
                    if (_updateAvailable)
                      TextButton(
                        onPressed: platform.update,
                        child: const Text('Atualizar aplicativo'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(key: const ValueKey('pwa-content'), child: widget.child),
      ],
    );
  }
}
