import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:flutter/material.dart';

/// Schedules the first overview load when [userId] and [isReady] allow it.
class OverviewAutoLoader extends StatefulWidget {
  const OverviewAutoLoader({
    required this.controller,
    required this.child,
    this.userId,
    this.isReady = false,
    super.key,
  });

  final OverviewController controller;
  final Widget child;
  final String? userId;
  final bool isReady;

  @override
  State<OverviewAutoLoader> createState() => _OverviewAutoLoaderState();
}

class _OverviewAutoLoaderState extends State<OverviewAutoLoader> {
  @override
  void initState() {
    super.initState();
    _scheduleLoadIfReady();
  }

  @override
  void didUpdateWidget(covariant OverviewAutoLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.isReady != widget.isReady) {
      _scheduleLoadIfReady();
    }
  }

  void _scheduleLoadIfReady() {
    final userId = widget.userId;
    if (!widget.isReady || userId == null || userId.isEmpty) {
      return;
    }
    widget.controller.scheduleOverviewLoadIfNeeded(userId: userId);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
