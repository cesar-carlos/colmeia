import 'dart:async';

import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/application/usecases/clear_active_store_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/load_current_user_context_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/persist_active_store_use_case.dart';
import 'package:colmeia/features/user_context/domain/entities/dashboard_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/report_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:colmeia/features/user_context/domain/entities/user_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:result_dart/result_dart.dart';

class CurrentUserContextController extends ChangeNotifier {
  CurrentUserContextController({
    AuthController? authController,
    LoadCurrentUserContextUseCase? loadCurrentUserContextUseCase,
    PersistActiveStoreUseCase? persistActiveStoreUseCase,
    ClearActiveStoreUseCase? clearActiveStoreUseCase,
    UserScope? userScope,
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
       _userScope = userScope ?? _placeholderUserScope,
       _activeStoreId = activeStoreId ?? _placeholderActiveStoreId {
    if (_authController != null) {
      _authController.addListener(_handleAuthStateChanged);
      _handleAuthStateChanged();
    }
  }

  CurrentUserContextController.testing({
    required UserScope userScope,
    required String activeStoreId,
  }) : this(
         userScope: userScope,
         activeStoreId: activeStoreId,
       );

  CurrentUserContextController.seeded()
    : this.testing(
        userScope: const UserScope(
          userId: 'seeded-user',
          name: 'Camila Oliveira',
          roleLabel: 'Gerente regional',
          allowedStores: <StoreScope>[
            StoreScope(id: '03', name: 'Loja Centro'),
            StoreScope(id: '08', name: 'Loja Norte'),
            StoreScope(id: '14', name: 'Loja Sul'),
          ],
          permissions: <UserPermission>{
            UserPermission.viewDashboard,
            UserPermission.viewReports,
          },
          dashboardGrants: <DashboardAccessGrant>[
            DashboardAccessGrant(
              dashboardId: 'dashboard_main',
              allowedFilterKeys: <String>{'store', 'referenceDate'},
            ),
          ],
          reportGrants: <ReportAccessGrant>[
            ReportAccessGrant(
              reportId: 'sales_overview',
              allowedFilterKeys: <String>{
                'store',
                'seller',
                'referenceDate',
                'onlyPositiveMargin',
              },
            ),
            ReportAccessGrant(
              reportId: 'margin_audit',
              allowedFilterKeys: <String>{
                'store',
                'seller',
                'referenceDate',
                'onlyPositiveMargin',
              },
            ),
          ],
        ),
        activeStoreId: '03',
      );

  static const String _placeholderActiveStoreId = 'loading-store';
  static const UserScope _placeholderUserScope = UserScope(
    userId: 'loading-user',
    name: 'Carregando usuario',
    roleLabel: 'Sincronizando acesso',
    allowedStores: <StoreScope>[
      StoreScope(id: _placeholderActiveStoreId, name: 'Carregando lojas...'),
    ],
    permissions: <UserPermission>{
      UserPermission.viewDashboard,
      UserPermission.viewReports,
    },
    dashboardGrants: <DashboardAccessGrant>[
      DashboardAccessGrant(
        dashboardId: 'dashboard_main',
        allowedFilterKeys: <String>{'store'},
      ),
    ],
    reportGrants: <ReportAccessGrant>[
      ReportAccessGrant(
        reportId: 'sales_overview',
        allowedFilterKeys: <String>{'store'},
      ),
    ],
  );

  final AuthController? _authController;
  final LoadCurrentUserContextUseCase? _loadCurrentUserContextUseCase;
  final PersistActiveStoreUseCase? _persistActiveStoreUseCase;
  final ClearActiveStoreUseCase? _clearActiveStoreUseCase;

  UserScope _userScope;
  String _activeStoreId;
  String? _errorMessage;
  bool _isLoading = false;
  String? _syncedUserId;

  UserScope get userScope => _userScope;
  Set<UserPermission> get permissions => _userScope.permissions;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

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
      case AppRoute.reports:
      case AppRoute.reportDetail:
        return hasAnyReportAccess();
      case AppRoute.dashboard:
      case AppRoute.dashboardStore:
        return hasAnyDashboardAccess();
      case AppRoute.login:
      case AppRoute.register:
      case AppRoute.settings:
        return true;
    }
  }

  bool hasAnyReportAccess() {
    return _userScope.hasAnyReportAccess();
  }

  bool hasAnyDashboardAccess() {
    return _userScope.hasAnyDashboardAccess();
  }

  bool canAccessReport(String reportId) {
    return _userScope.canAccessReport(reportId);
  }

  bool canAccessDashboard(String dashboardId) {
    return _userScope.canAccessDashboard(dashboardId);
  }

  Set<String> allowedReportFilterKeys(String reportId) {
    return _userScope.allowedReportFilterKeys(reportId);
  }

  Set<String> allowedDashboardFilterKeys(String dashboardId) {
    return _userScope.allowedDashboardFilterKeys(dashboardId);
  }

  List<AppRoute> get availableShellRoutes {
    return AppRoute.shellRoutes.where(canAccessRoute).toList();
  }

  void _handleAuthStateChanged() {
    unawaited(_syncAuthState());
  }

  Future<void> _syncAuthState() async {
    final authController = _authController;
    final loadCurrentUserContextUseCase = _loadCurrentUserContextUseCase;
    final clearActiveStoreUseCase = _clearActiveStoreUseCase;
    if (authController == null ||
        loadCurrentUserContextUseCase == null ||
        clearActiveStoreUseCase == null) {
      return;
    }

    final session = authController.session;
    if (session == null) {
      final previousUserId = _syncedUserId;
      _syncedUserId = null;
      _userScope = _placeholderUserScope;
      _activeStoreId = _placeholderActiveStoreId;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      if (previousUserId != null) {
        await clearActiveStoreUseCase(userId: previousUserId);
      }
      return;
    }

    if (_syncedUserId == session.userId && !_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await loadCurrentUserContextUseCase(userId: session.userId);
    result.fold(
      (snapshot) {
        _userScope = snapshot.userScope;
        _activeStoreId = snapshot.activeStoreId;
        _syncedUserId = session.userId;
        _errorMessage = null;
      },
      (failure) {
        _userScope = _placeholderUserScope;
        _activeStoreId = _placeholderActiveStoreId;
        _syncedUserId = session.userId;
        _errorMessage = failure.displayMessage;
      },
    );

    _isLoading = false;
    notifyListeners();
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
          ),
        );
      }
    }
    notifyListeners();
    return Success<StoreScope, AppFailure>(store);
  }

  @override
  void dispose() {
    _authController?.removeListener(_handleAuthStateChanged);
    super.dispose();
  }
}
