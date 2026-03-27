import 'package:colmeia/app/router/app_routes.dart';

abstract interface class AppRouteData {
  AppRoute get route;
  Map<String, String> get pathParameters;
  Map<String, dynamic> get queryParameters;
}
