/// Compile-time switches for optional product areas. Prefer `const bool` here
/// until remote config is required; document any pairing with router behavior.
abstract final class AppFeatureFlags {
  /// When true, `/reports` and `/reports/*` redirect to the dashboard so old
  /// bookmarks do not land on an undefined route. Set to false when a real
  /// reports module registers matching routes in the same release.
  static const bool legacyReportsPathsRedirectToDashboard = true;
}
