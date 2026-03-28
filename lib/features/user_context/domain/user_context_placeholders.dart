/// Placeholder store id while user context is loading or reset.
abstract final class UserContextPlaceholders {
  UserContextPlaceholders._();

  static const String loadingStoreId = 'loading-store';

  static bool isLoadingStoreId(String id) => id == loadingStoreId;
}
