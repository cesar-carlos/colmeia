import 'dart:async';

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

/// Minimal shell shown when cold-start bootstrap fails before the main app.
class BootstrapFailureApp extends StatefulWidget {
  const BootstrapFailureApp({
    required this.onRetry,
    super.key,
    this.message,
    this.onClearCacheAndRetry,
  });

  final Future<void> Function() onRetry;
  final String? message;

  /// When set, shows a secondary action to wipe local Hive cache before retry.
  final Future<void> Function()? onClearCacheAndRetry;

  @override
  State<BootstrapFailureApp> createState() => _BootstrapFailureAppState();
}

class _BootstrapFailureAppState extends State<BootstrapFailureApp> {
  bool _isRetrying = false;
  bool _isClearingCache = false;

  bool get _isBusy => _isRetrying || _isClearingCache;

  Future<void> _handleRetry() async {
    if (_isBusy) {
      return;
    }
    setState(() => _isRetrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  Future<void> _handleClearCacheAndRetry() async {
    final onClearCacheAndRetry = widget.onClearCacheAndRetry;
    if (onClearCacheAndRetry == null || _isBusy) {
      return;
    }
    setState(() => _isClearingCache = true);
    try {
      await onClearCacheAndRetry();
    } finally {
      if (mounted) {
        setState(() => _isClearingCache = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Builder(
        builder: (context) {
          final tokens = Theme.of(context).extension<AppThemeTokens>()!;
          final onClearCacheAndRetry = widget.onClearCacheAndRetry;
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(tokens.pagePaddingHorizontalComfortable),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: AppInlineErrorPanel(
                      title: 'Não foi possível iniciar o aplicativo',
                      message: widget.message ??
                          'Ocorreu um erro ao preparar o Colmeia. '
                              'Tente novamente.',
                      actions: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AppPrimaryButton(
                            label: 'Tentar novamente',
                            isLoading: _isRetrying,
                            onPressed:
                                _isBusy ? null : () => unawaited(_handleRetry()),
                            fillWidth: true,
                          ),
                          if (onClearCacheAndRetry != null) ...<Widget>[
                            SizedBox(height: tokens.gapSm),
                            AppSecondaryButton(
                              label: 'Limpar cache local e tentar',
                              isLoading: _isClearingCache,
                              onPressed: _isBusy
                                  ? null
                                  : () => unawaited(_handleClearCacheAndRetry()),
                              fillWidth: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
