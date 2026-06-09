import 'package:colmeia/core/update/windows_auto_update_controller.dart';
import 'package:colmeia/core/update/windows_auto_update_messages.dart';
import 'package:colmeia/core/update/windows_auto_update_state.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:flutter/material.dart';

class WindowsAutoUpdateSettingsTile extends StatelessWidget {
  const WindowsAutoUpdateSettingsTile({
    required this.controller,
    super.key,
  });

  final WindowsAutoUpdateController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        if (!state.shouldShowInSettings) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final localizations = MaterialLocalizations.of(context);
        final tokens = theme.extension<AppThemeTokens>()!;
        final typography = theme.appTypography;
        final cs = theme.colorScheme;
        final accentColor = _resolveAccentColor(state, cs);
        final showFullDetails =
            state.status == WindowsAutoUpdateStatus.unavailable;

        return AppSectionCardWithHeading(
          titleWidget: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(tokens.gapMd),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.system_update_alt_rounded,
                  color: accentColor,
                ),
              ),
              SizedBox(width: tokens.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      WindowsAutoUpdateMessages.settingsTitle,
                      style: typography.sectionHeaderH2.copyWith(
                        fontSize: theme.textTheme.titleSmall?.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: tokens.gapXs),
                    Text(
                      WindowsAutoUpdateMessages.settingsStatusLabel(
                        state.status,
                      ),
                      style: typography.utilityOverline.copyWith(
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          headingTrailing: _AutoUpdateStatusIndicator(state: state),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                state.headline,
                style: typography.caption.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (state.details case final String details) ...<Widget>[
                SizedBox(height: tokens.gapXs),
                Text(
                  details,
                  maxLines: showFullDetails ? null : 3,
                  overflow: showFullDetails ? null : TextOverflow.ellipsis,
                  style: typography.caption.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
              if (state.lastCheckedAt
                  case final DateTime lastCheckedAt) ...<Widget>[
                SizedBox(height: tokens.gapXs),
                Text(
                  _lastCheckedLabel(lastCheckedAt, localizations),
                  style: typography.caption.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
              SizedBox(height: tokens.gapMd),
              Align(
                alignment: Alignment.centerLeft,
                child: AppFlatButton(
                  icon: const Icon(Icons.refresh_rounded),
                  label: state.isChecking
                      ? WindowsAutoUpdateMessages.checkingButtonLabel
                      : WindowsAutoUpdateMessages.checkButtonLabel,
                  semanticsLabel:
                      WindowsAutoUpdateMessages.checkButtonSemanticsLabel,
                  fillWidth: false,
                  isLoading: state.isChecking,
                  onPressed: state.canCheckForUpdates
                      ? controller.checkForUpdates
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Color _resolveAccentColor(WindowsAutoUpdateState state, ColorScheme cs) {
  return switch (state.status) {
    WindowsAutoUpdateStatus.failed => cs.error,
    WindowsAutoUpdateStatus.unavailable => cs.onSurfaceVariant,
    _ => cs.primary,
  };
}

String _lastCheckedLabel(
  DateTime lastCheckedAt,
  MaterialLocalizations localizations,
) {
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(lastCheckedAt),
  );
  final date = localizations.formatShortDate(lastCheckedAt);
  return WindowsAutoUpdateMessages.lastCheckedLabel(
    date: date,
    time: time,
  );
}

class _AutoUpdateStatusIndicator extends StatelessWidget {
  const _AutoUpdateStatusIndicator({
    required this.state,
  });

  final WindowsAutoUpdateState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (state.isChecking) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: cs.primary,
        ),
      );
    }

    final (icon, color) = switch (state.status) {
      WindowsAutoUpdateStatus.updateAvailable => (
        Icons.download_for_offline_rounded,
        cs.primary,
      ),
      WindowsAutoUpdateStatus.upToDate => (
        Icons.verified_rounded,
        cs.primary,
      ),
      WindowsAutoUpdateStatus.feedWithoutReleases => (
        Icons.info_outline_rounded,
        cs.onSurfaceVariant,
      ),
      WindowsAutoUpdateStatus.readyToInstall => (
        Icons.task_alt_rounded,
        cs.primary,
      ),
      WindowsAutoUpdateStatus.failed => (
        Icons.error_outline_rounded,
        cs.error,
      ),
      WindowsAutoUpdateStatus.unavailable => (
        Icons.info_outline_rounded,
        cs.onSurfaceVariant,
      ),
      WindowsAutoUpdateStatus.idle => (
        Icons.sync_rounded,
        cs.onSurfaceVariant,
      ),
      WindowsAutoUpdateStatus.checking => (
        Icons.sync_rounded,
        cs.primary,
      ),
    };

    return Icon(icon, color: color);
  }
}
