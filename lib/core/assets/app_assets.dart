/// Compile-time constants for every bundled asset path used at runtime.
///
/// Usage:
///   Image.asset(AppAssets.logo)
///   AssetImage(AppAssets.logo)
///
/// Env file paths live in `EnvAssetPaths` (see `core/config/env_keys.dart`).
/// Launcher icon sources under `assets/icons/` are build-time only and are
/// not listed here.
abstract final class AppAssets {
  // ---------------------------------------------------------------------------
  // Images — assets/images/
  // ---------------------------------------------------------------------------

  // Add entries here as images are added to assets/images/.
  // Example:
  //   static const String logo = 'assets/images/colmeia_logo.svg';
  //   static const String onboardingHero = 'assets/images/onboarding_hero.png';

  // ---------------------------------------------------------------------------
  // Animations — assets/animations/
  // ---------------------------------------------------------------------------

  // Add entries here as Lottie/Rive files are added to assets/animations/.
  // Example:
  //   static const String loadingBee = 'assets/animations/loading_bee.json';
  //   static const String successCheck = 'assets/animations/success_check.json';
}
