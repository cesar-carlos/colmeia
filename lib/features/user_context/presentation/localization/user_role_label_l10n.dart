import 'package:colmeia/l10n/app_localizations.dart';

String userRoleLabelDisplay(AppLocalizations l10n, String roleLabel) {
  final normalized = roleLabel.trim().toLowerCase();
  return switch (normalized) {
    'client (active)' => l10n.userRoleClientActive,
    'client (pending)' => l10n.userRoleClientPending,
    'client (rejected)' => l10n.userRoleClientRejected,
    'client (blocked)' => l10n.userRoleClientBlocked,
    'active' => l10n.userRoleStatusActive,
    'pending' => l10n.userRoleStatusPending,
    'rejected' => l10n.userRoleStatusRejected,
    'blocked' => l10n.userRoleStatusBlocked,
    'unknown' => l10n.userRoleStatusUnknown,
    _ => roleLabel,
  };
}
