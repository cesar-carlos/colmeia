import 'dart:async';

import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:flutter/material.dart';

/// Schedules the first overview load when [userId] and [isReady] allow it.
class OverviewAutoLoader extends StatefulWidget {
  const OverviewAutoLoader({
    required this.controller,
    required this.loadingMode,
    required this.rowLabels,
    required this.failureMessageBuilder,
    required this.child,
    this.userId,
    this.isReady = false,
    super.key,
  });

  final OverviewController controller;
  final OverviewLoadingMode loadingMode;
  final OverviewLoadLabels rowLabels;
  final OverviewFailureMessageBuilder failureMessageBuilder;
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
    if (oldWidget.loadingMode != widget.loadingMode) {
      _reloadForLoadingModeIfReady();
      return;
    }
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
    widget.controller.scheduleOverviewLoadIfNeeded(
      userId: userId,
      loadingMode: widget.loadingMode,
      rowLabels: widget.rowLabels,
      failureMessageBuilder: widget.failureMessageBuilder,
    );
  }

  void _reloadForLoadingModeIfReady() {
    final userId = widget.userId;
    if (!widget.isReady || userId == null || userId.isEmpty) {
      return;
    }

    final future = widget.controller.hasContent
        ? widget.controller.refreshOverview(
            userId: userId,
            loadingMode: widget.loadingMode,
            rowLabels: widget.rowLabels,
            failureMessageBuilder: widget.failureMessageBuilder,
          )
        : widget.controller.loadOverview(
            userId: userId,
            loadingMode: widget.loadingMode,
            rowLabels: widget.rowLabels,
            failureMessageBuilder: widget.failureMessageBuilder,
          );
    unawaited(future);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
