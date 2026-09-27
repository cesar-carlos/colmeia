import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class SalesLiveMapIntroSection extends StatelessWidget {
  const SalesLiveMapIntroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppShellPageIntro(
      title: l10n.salesLiveMapTitle,
      subtitle: l10n.salesLiveMapSubtitle,
    );
  }
}
