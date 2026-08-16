import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/refresh/app_second_ticker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef AutoRefreshCountdownLabelBuilder = String Function(
  Duration remaining, {
  required bool isBackingOff,
});

class AutoRefreshCountdownText extends StatefulWidget {
  const AutoRefreshCountdownText({
    required this.nextDueAt,
    required this.isBackingOff,
    required this.labelBuilder,
    super.key,
    this.ticker,
  });

  final DateTime nextDueAt;
  final bool isBackingOff;
  final AutoRefreshCountdownLabelBuilder labelBuilder;
  final ValueListenable<DateTime>? ticker;

  @override
  State<AutoRefreshCountdownText> createState() =>
      _AutoRefreshCountdownTextState();
}

class _AutoRefreshCountdownTextState extends State<AutoRefreshCountdownText> {
  late ValueListenable<DateTime> _ticker;
  late DateTime _now;
  bool _listeningToTicker = false;

  @override
  void initState() {
    super.initState();
    _ticker = widget.ticker ?? AppSecondTicker.instance;
    _now = _ticker.value;
    _syncTickerSubscription();
  }

  @override
  void didUpdateWidget(covariant AutoRefreshCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextTicker = widget.ticker ?? AppSecondTicker.instance;
    if (!identical(_ticker, nextTicker)) {
      _detachTickerListener();
      _ticker = nextTicker;
    }
    _now = _ticker.value;
    _syncTickerSubscription();
  }

  @override
  void dispose() {
    _detachTickerListener();
    super.dispose();
  }

  void _handleTick() {
    if (!mounted) {
      return;
    }
    final now = _ticker.value;
    final shouldListen = widget.nextDueAt.isAfter(now);
    if (!shouldListen) {
      _detachTickerListener();
    }
    setState(() {
      _now = now;
    });
  }

  void _syncTickerSubscription() {
    final shouldListen = widget.nextDueAt.isAfter(_now);
    if (shouldListen == _listeningToTicker) {
      return;
    }
    if (shouldListen) {
      _ticker.addListener(_handleTick);
      _listeningToTicker = true;
      return;
    }
    _detachTickerListener();
  }

  void _detachTickerListener() {
    if (!_listeningToTicker) {
      return;
    }
    _ticker.removeListener(_handleTick);
    _listeningToTicker = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = widget.nextDueAt.difference(_now);
    final clamped = remaining <= Duration.zero ? Duration.zero : remaining;
    return Text(
      widget.labelBuilder(clamped, isBackingOff: widget.isBackingOff),
      style: theme.appTypography.caption.copyWith(
        color: widget.isBackingOff
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: widget.isBackingOff ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
