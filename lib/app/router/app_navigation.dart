import 'package:colmeia/app/router/app_route_data.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension AppNavigation on BuildContext {
  void goTo(
    AppRoute route, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
    String? fragment,
  }) {
    goNamed(
      route.name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
      fragment: fragment,
    );
  }

  Future<T?> pushTo<T extends Object?>(
    AppRoute route, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    return pushNamed<T>(
      route.name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  void replaceWith(
    AppRoute route, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    replaceNamed(
      route.name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  void goToData(AppRouteData routeData, {Object? extra, String? fragment}) {
    goTo(
      routeData.route,
      pathParameters: routeData.pathParameters,
      queryParameters: routeData.queryParameters,
      extra: extra,
      fragment: fragment,
    );
  }

  Future<T?> pushToData<T extends Object?>(
    AppRouteData routeData, {
    Object? extra,
  }) {
    return pushTo<T>(
      routeData.route,
      pathParameters: routeData.pathParameters,
      queryParameters: routeData.queryParameters,
      extra: extra,
    );
  }

  void replaceWithData(AppRouteData routeData, {Object? extra}) {
    replaceWith(
      routeData.route,
      pathParameters: routeData.pathParameters,
      queryParameters: routeData.queryParameters,
      extra: extra,
    );
  }
}
