import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    required this.enabled,
    required this.child,
    this.showDelay = const Duration(milliseconds: 180),
    this.transitionDuration = const Duration(milliseconds: 220),
    this.loadingSemanticsLabel = 'Carregando dados...',
    super.key,
  });

  final bool enabled;
  final Widget child;
  final Duration showDelay;
  final Duration transitionDuration;
  final String loadingSemanticsLabel;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> {
  bool _delayElapsed = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _syncDelayState();
  }

  @override
  void didUpdateWidget(covariant AppSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final toggledToEnabled = !oldWidget.enabled && widget.enabled;
    final delayChangedWhileEnabled =
        oldWidget.showDelay != widget.showDelay && widget.enabled;
    if (toggledToEnabled || delayChangedWhileEnabled) {
      _syncDelayState();
    } else if (!widget.enabled) {
      _cancelDelayTimer();
      if (_delayElapsed) {
        setState(() {
          _delayElapsed = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cancelDelayTimer();
    super.dispose();
  }

  void _cancelDelayTimer() {
    _delayTimer?.cancel();
    _delayTimer = null;
  }

  void _syncDelayState() {
    _cancelDelayTimer();
    if (!widget.enabled) {
      _delayElapsed = false;
      return;
    }

    if (widget.showDelay <= Duration.zero) {
      _delayElapsed = true;
      return;
    }

    _delayElapsed = false;
    _delayTimer = Timer(widget.showDelay, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _delayElapsed = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowSkeleton = widget.enabled && _delayElapsed;
    final childKey = ValueKey<bool>(shouldShowSkeleton);
    final body = AnimatedSwitcher(
      duration: widget.transitionDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: childKey,
        child: Skeletonizer(
          enabled: shouldShowSkeleton,
          child: widget.child,
        ),
      ),
    );

    final semanticsWrapped =
        widget.enabled
            ? Semantics(
              container: true,
              liveRegion: true,
              label: widget.loadingSemanticsLabel,
              child: body,
            )
            : body;

    return AbsorbPointer(
      absorbing: widget.enabled,
      child: semanticsWrapped,
    );
  }
}
