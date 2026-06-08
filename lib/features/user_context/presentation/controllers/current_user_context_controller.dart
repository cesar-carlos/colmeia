import 'dart:async';

import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_target_warm_up_coordinator.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/overview/application/overview_shell_cache.dart';
import 'package:colmeia/features/user_context/application/usecases/clear_active_store_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/load_current_user_context_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/persist_active_store_use_case.dart';
import 'package:colmeia/features/user_context/domain/entities/access/dashboard_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/current_user_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_access_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';
import 'package:colmeia/features/user_context/domain/user_context_placeholders.dart';
import 'package:flutter/foundation.dart';
import 'package:result_dart/result_dart.dart';

class CurrentUserContextController extends ChangeNotifier {
  CurrentUserContextController({
    AuthController? authController,
    LoadCurrentUserContextUseCase? loadCurrentUserContextUseCase,
    PersistActiveStoreUseCase? persistActiveStoreUseCase,
    ClearActiveStoreUseCase? clearActiveStoreUseCase,
    OverviewShellCache? overviewShellCache,
    AgentQueryTargetWarmUpCoordinator? agentQueryTargetWarmUpCoordinator,
    CurrentUserScope? userScope,
    String? activeStoreId,
  }) : assert(
         (authController != null &&
                 loadCurrentUserContextUseCase != null &&
                 persistActiveStoreUseCase != null &&
                 clearActiveStoreUseCase != null) ||
             (userScope != null && activeStoreId != null),
         'Provide auth dependencies or user scope data.',
       ),
       _authController = authController,
       _loadCurrentUserContextUseCase = loadCurrentUserContextUseCase,
       _persistActiveStoreUseCase = persistActiveStoreUseCase,
       _clearActiveStoreUseCase = clearActiveStoreUseCase,
       _overviewShellCache = overviewShellCache,
       _agentQueryTargetWarmUpCoordinator = agentQueryTargetWarmUpCoordinator,
       _userScope = userScope ?? _placeholderUserScope,
       _activeStoreId =
           activeStoreId ?? UserContextPlaceholders.loadingStoreId {
    _availableShellRoutes = _computeAvailableShellRoutes();
    if (_authController != null) {
      _authController.addListener(_handleAuthStateChanged);
      _handleAuthStateChanged();
    }
  }

  CurrentUserContextController.testing({
    required CurrentUserScope userScope,
    required String activeStoreId,
  }) : this(
         userScope: userScope,
         activeStoreId: activeStoreId,
       );

  CurrentUserContextController.seeded()
    : this.testing(
        userScope: const CurrentUserScope(
          profile: UserProfile(
            id: 'seeded-user',
            name: 'Camila Oliveira',
            roleLabel: 'Gerente regional',
            corporateEmail: 'camila@example.com',
            phone: '+55 (11) 98765-4321',
          ),
          access: UserAccessScope(
            allowedStores: <StoreScope>[
              StoreScope(id: '03', name: 'Loja Centro'),
              StoreScope(id: '08', name: 'Loja Norte'),
              StoreScope(id: '14', name: 'Loja Sul'),
            ],
            permissions: <UserPermission>{
              UserPermission.viewDashboard,
              UserPermission.viewSales,
              UserPermission.viewReturns,
              UserPermission.viewFinance,
              UserPermission.viewPurchases,
              UserPermission.viewInventory,
            },
            dashboardGrants: <DashboardAccessGrant>[
              DashboardAccessGrant(
                dashboardId: 'dashboard_main',
                allowedFilterKeys: <String>{'store', 'referenceDate'},
              ),
            ],
          ),
        ),
        activeStoreId: '03',
      );

  static const CurrentUserScope _placeholderUserScope = CurrentUserScope(
    profile: UserProfile(
      id: 'loading-user',
      name: 'Carregando usuario',
      roleLabel: 'Sincronizando acesso',
    ),
    access: UserAccessScope(
      allowedStores: <StoreScope>[
        StoreScope(
          id: UserContextPlaceholders.loadingStoreId,
          name: 'Conta do cliente',
        ),
      ],
      permissions: <UserPermission>{},
    ),
  );

  final AuthController? _authController;
  final LoadCurrentUserContextUseCase? _loadCurrentUserContextUseCase;
  final PersistActiveStoreUseCase? _persistActiveStoreUseCase;
  final ClearActiveStoreUseCase? _clearActiveStoreUseCase;
  final OverviewShellCache? _overviewShellCache;
  final AgentQueryTargetWarmUpCoordinator? _agentQueryTargetWarmUpCoordinator;

  CurrentUserScope _userScope;
  late List<AppRoute> _availableShellRoutes;
  String _activeStoreId;
  String? _errorMessage;
  bool _isLoadingInitial = false;
  bool _isRefreshing = false;
  String? _syncedUserId;
  int _syncGeneration = 0;
  bool _isDisposed = false;

  CurrentUserScope get userScope => _userScope;
  Set<UserPermission> get permissions => _userScope.permissions;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoadingInitial || _isRefreshing;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isRefreshing => _isRefreshing;

  StoreScope get activeStore {
    return _userScope.allowedStores.firstWhere(
      (store) => store.id == _activeStoreId,
      orElse: () => _userScope.allowedStores.first,
    );
  }

  bool hasPermission(UserPermission permission) {
    return permissions.contains(permission);
  }

  bool canAccessRoute(AppRoute route) {
    switch (route) {
      case AppRoute.unmatched:
        return false;
      case AppRoute.dashboard:
      case AppRoute.dashboardStore:
        return hasAnyDashboardAccess();
      case AppRoute.login:
      case AppRoute.register:
      case AppRoute.registrationStatus:
      case AppRoute.passwordRecovery:
      case AppRoute.passwordRecoveryReset:
      case AppRoute.settings:
      case AppRoute.chartFullscreen:
      case AppRoute.agents:
      case AppRoute.agentsDetail:
        return true;
      case AppRoute.sales:
      case AppRoute.salesCard:
      case AppRoute.salesMonitoring:
        return hasPermission(UserPermission.viewSales);
      case AppRoute.inventory:
        return hasPermission(UserPermission.viewInventory);
    }
  }

  bool hasAnyDashboardAccess() {
    return _userScope.hasAnyDashboardAccess();
  }

  bool canAccessDashboard(String dashboardId) {
    return _userScope.canAccessDashboard(dashboardId);
  }

  Set<String> allowedOverviewFilterKeys(String dashboardId) {
    return _userScope.allowedOverviewFilterKeys(dashboardId);
  }

  List<AppRoute> get availableShellRoutes {
    return _availableShellRoutes;
  }

  List<AppRoute> _computeAvailableShellRoutes() {
    final available = <AppRoute>[];
    for (final route in AppRoute.shellRoutes) {
      if (canAccessRoute(route)) {
        available.add(route);
        continue;
      }
      final requiredPermission = route.requiredPermission;
      if (kDebugMode && requiredPermission != null) {
        AppLogger.debug(
          'Shell route hidden by missing permission',
          context: <String, Object?>{
            'operation': 'computeAvailableShellRoutes',
            'route': route.name,
            'requiredPermission': requiredPermission.name,
          },
        );
      }
    }
    return List<AppRoute>.unmodifiable(available);
  }

  void _handleAuthStateChanged() {
    unawaited(
      _syncAuthState().catchError((Object error, StackTrace stackTrace) {
        AppLogger.error(
          'User context sync failed after auth change',
          context: const <String, Object?>{
            'operation': 'syncUserContext',
          },
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  /// Applies profile fields from an API response without a follow-up GET.
  ///
  /// Keeps current access grants and active store selection. Call after a
  /// successful profile PATCH or thumbnail upload when the response already
  /// contains the authoritative profile snapshot.
  void applyUpdatedProfile(UserProfile profile) {
    _userScope = CurrentUserScope(
      profile: profile,
      access: _userScope.access,
    );
    _availableShellRoutes = _computeAvailableShellRoutes();
    _notifyListenersIfAlive();
  }

  /// Forces a reload from the server (e.g. user tapped retry after an error).
  Future<void> reloadUserContext() async {
    final authController = _authController;
    final session = authController?.session;
    if (authController == null || session == null) {
      return;
    }
    await _syncAuthState(
      forceReload: true,
      keepContentVisible: hasResolvedData,
    );
  }

  bool get hasResolvedData {
    return _syncedUserId != null &&
        !UserContextPlaceholders.isLoadingStoreId(_activeStoreId);
  }

  Future<void> _syncAuthState({
    bool forceReload = false,
    bool keepContentVisible = false,
  }) async {
    final authController = _authController;
    final loadCurrentUserContextUseCase = _loadCurrentUserContextUseCase;
    final clearActiveStoreUseCase = _clearActiveStoreUseCase;
    if (authController == null ||
        loadCurrentUserContextUseCase == null ||
        clearActiveStoreUseCase == null) {
      return;
    }

    final generation = ++_syncGeneration;
    final session = authController.session;
    if (session == null) {
      final previousUserId = _syncedUserId;
      _syncedUserId = null;
      _userScope = _placeholderUserScope;
      _availableShellRoutes = _computeAvailableShellRoutes();
      _activeStoreId = UserContextPlaceholders.loadingStoreId;
      _errorMessage = null;
      _isLoadingInitial = false;
      _isRefreshing = false;
      _notifyListenersIfAlive();
      if (previousUserId != null) {
        await clearActiveStoreUseCase(userId: previousUserId);
      }
      _overviewShellCache?.invalidate();
      _agentQueryTargetWarmUpCoordinator?.invalidate();
      return;
    }

    if (_syncedUserId == session.userId && !forceReload && !isLoading) {
      return;
    }

    if (keepContentVisible) {
      _isLoadingInitial = false;
      _isRefreshing = true;
    } else {
      _isRefreshing = false;
      _isLoadingInitial = true;
      _userScope = _placeholderUserScope;
      _availableShellRoutes = _computeAvailableShellRoutes();
      _activeStoreId = UserContextPlaceholders.loadingStoreId;
    }
    _errorMessage = null;
    _notifyListenersIfAlive();

    final result = await loadCurrentUserContextUseCase(
      userId: session.userId,
    );
    if (_isDisposed || generation != _syncGeneration) {
      return;
    }

    result.fold(
      (snapshot) {
        _userScope = snapshot.scope;
        _availableShellRoutes = _computeAvailableShellRoutes();
        _activeStoreId = snapshot.activeStoreId;
        _syncedUserId = session.userId;
        _errorMessage = null;
        _agentQueryTargetWarmUpCoordinator?.scheduleWarmUp(
          userId: session.userId,
        );
      },
      (failure) {
        _syncedUserId = session.userId;
        if (!keepContentVisible) {
          _userScope = _placeholderUserScope;
          _availableShellRoutes = _computeAvailableShellRoutes();
          _activeStoreId = UserContextPlaceholders.loadingStoreId;
        }
        _errorMessage = failure.displayMessage;
      },
    );

    if (keepContentVisible) {
      _isRefreshing = false;
    } else {
      _isLoadingInitial = false;
    }
    _notifyListenersIfAlive();
  }

  AppResult<StoreScope> resolveStore({
    StoreId? preferredStoreId,
  }) {
    if (preferredStoreId == null) {
      _errorMessage = null;
      AppLogger.debug(
        'Resolved current active store',
        context: <String, Object?>{
          'operation': 'resolveStore',
          'storeId': activeStore.id,
        },
      );
      return Success<StoreScope, AppFailure>(activeStore);
    }

    final store = _userScope.allowedStores
        .where((allowedStore) => allowedStore.id == preferredStoreId.value)
        .firstOrNull;

    if (store == null) {
      final failure = ValidationFailure(
        message: 'Requested store is outside the user scope',
        userMessage: 'A loja solicitada nao esta disponivel para este usuario.',
        context: <String, Object?>{
          'operation': 'resolveStore',
          'storeId': preferredStoreId.value,
        },
      );
      _errorMessage = failure.displayMessage;
      AppLogger.warning(
        'Requested store is outside user scope',
        context: <String, Object?>{
          'operation': 'resolveStore',
          'storeId': preferredStoreId.value,
        },
      );
      return Failure<StoreScope, AppFailure>(failure);
    }

    _errorMessage = null;
    AppLogger.debug(
      'Resolved store inside user scope',
      context: <String, Object?>{
        'operation': 'resolveStore',
        'storeId': store.id,
      },
    );
    return Success<StoreScope, AppFailure>(store);
  }

  AppResult<StoreScope> selectStore(String storeId) {
    if (storeId == _activeStoreId) {
      _errorMessage = null;
      AppLogger.debug(
        'Store selection ignored because it is already active',
        context: <String, Object?>{
          'operation': 'selectStore',
          'storeId': storeId,
        },
      );
      return Success<StoreScope, AppFailure>(activeStore);
    }

    final resolvedStore = resolveStore(preferredStoreId: StoreId(storeId));
    final store = resolvedStore.getOrNull();
    if (store == null) {
      return resolvedStore;
    }

    _activeStoreId = storeId;
    _errorMessage = null;
    AppLogger.info(
      'Active store changed in controller',
      context: <String, Object?>{
        'operation': 'selectStore',
        'storeId': store.id,
      },
    );
    final syncedUserId = _syncedUserId;
    if (syncedUserId != null) {
      final persistActiveStoreUseCase = _persistActiveStoreUseCase;
      if (persistActiveStoreUseCase != null) {
        unawaited(
          persistActiveStoreUseCase(
            userId: syncedUserId,
            storeId: storeId,
          ).catchError((Object error, StackTrace stackTrace) {
            AppLogger.warning(
              'Persist active store failed',
              context: <String, Object?>{
                'operation': 'persistActiveStore',
                'storeId': storeId,
              },
              error: error,
              stackTrace: stackTrace,
            );
          }),
        );
      }
    }
    _notifyListenersIfAlive();
    return Success<StoreScope, AppFailure>(store);
  }

  void _notifyListenersIfAlive() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authController?.removeListener(_handleAuthStateChanged);
    super.dispose();
  }
}
