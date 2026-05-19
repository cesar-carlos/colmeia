import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_route_data.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef AppChartFullscreenBuilder = Widget Function(BuildContext context);
typedef AppChartFullscreenHeaderBuilder = Widget Function(BuildContext context);

final class AppChartFullscreenRouteData implements AppRouteData {
  const AppChartFullscreenRouteData();

  @override
  AppRoute get route => AppRoute.chartFullscreen;

  @override
  Map<String, String> get pathParameters => const <String, String>{};

  @override
  Map<String, dynamic> get queryParameters => const <String, dynamic>{};
}

final class AppChartFullscreenRouteExtra {
  const AppChartFullscreenRouteExtra({
    required this.chartBuilder,
    this.headerBuilder,
    this.title,
    this.subtitle,
    this.filterSummary,
    this.headerTrailing,
    this.bodyPadding,
    this.chartSemanticsLabel,
  });

  final AppChartFullscreenBuilder chartBuilder;
  final AppChartFullscreenHeaderBuilder? headerBuilder;
  final String? title;
  final String? subtitle;
  final String? filterSummary;
  final Widget? headerTrailing;

  /// Optional insets merged into [AppChartFullscreenScaffold] defaults: default
  /// top/bottom gaps are preserved via [EdgeInsetsGeometry.resolve] merge (at
  /// least the scaffold minimum). Horizontal content margins are applied inside
  /// the fullscreen [Scaffold] body.
  final EdgeInsetsGeometry? bodyPadding;
  final String? chartSemanticsLabel;
}

extension AppChartFullscreenNavigation on BuildContext {
  Future<T?> pushChartFullscreen<T extends Object?>({
    required AppChartFullscreenRouteExtra extra,
  }) {
    return pushToData<T>(
      const AppChartFullscreenRouteData(),
      extra: extra,
    );
  }
}

List<RouteBase> buildAppChartFullscreenRoutes() {
  return <RouteBase>[
    GoRoute(
      name: AppRoute.chartFullscreen.name,
      path: AppRoute.chartFullscreen.path,
      builder: _buildChartFullscreenRoute,
    ),
  ];
}

Widget _buildChartFullscreenRoute(BuildContext context, GoRouterState state) {
  final payload = state.extra;
  final l10n = AppLocalizations.of(context);
  assert(
    payload == null || payload is AppChartFullscreenRouteExtra,
    'AppRoute.chartFullscreen expects AppChartFullscreenRouteExtra in state.extra.',
  );

  if (payload is! AppChartFullscreenRouteExtra) {
    return AppChartFullscreenScaffold(
      title: l10n.chartFullscreenUnavailableTitle,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.chartFullscreenUnavailableMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }

  Widget chart = Builder(builder: payload.chartBuilder);
  final headerBuilder = payload.headerBuilder;
  final header = headerBuilder == null ? null : Builder(builder: headerBuilder);
  final semanticsLabel = payload.chartSemanticsLabel?.trim();
  if (semanticsLabel != null && semanticsLabel.isNotEmpty) {
    chart = Semantics(
      label: semanticsLabel,
      child: chart,
    );
  }

  return AppChartFullscreenScaffold(
    header: header,
    title: payload.title,
    subtitle: payload.subtitle,
    filterSummary: payload.filterSummary,
    headerTrailing: payload.headerTrailing,
    bodyPadding: payload.bodyPadding,
    child: chart,
  );
}
