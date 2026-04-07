import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Binds [AppLocalizations] on every dependency change (locale updates).
///
/// Implement [bindAppLocalizations] to push strings into a controller.
mixin SyncAppLocalizationsMixin<T extends StatefulWidget> on State<T> {
  void bindAppLocalizations(AppLocalizations l10n);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bindAppLocalizations(AppLocalizations.of(context));
  }
}
