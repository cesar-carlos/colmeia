import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/settings/presentation/pages/chart_demo_showcase_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppBrazilStoreSalesMapChartDemoPage extends StatefulWidget {
  const AppBrazilStoreSalesMapChartDemoPage({super.key});

  @override
  State<AppBrazilStoreSalesMapChartDemoPage> createState() =>
      _AppBrazilStoreSalesMapChartDemoPageState();
}

class _AppBrazilStoreSalesMapChartDemoPageState
    extends State<AppBrazilStoreSalesMapChartDemoPage> {
  AppBrazilStoreSalesMapPreset _selectedMapPreset = _lastSelectedMapPreset;
  String? _eventSummary;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);
    final selectedMapPreset = _selectedMapPreset;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Mapas interativos',
          title: 'AppBrazilStoreSalesMapChart',
          subtitle:
              'Mapa do Brasil por UF com pontos de lojas, agregacao por '
              'receita ou vendas e eventos tipados para dashboards.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        const ChartDemoShowcaseCard(
          icon: Icons.storefront_rounded,
          title: 'Vendas por loja no mapa do Brasil',
          subtitle:
              'Componente compartilhado com GeoJSON embarcado, metadados '
              'territoriais estaticos e dados fake agregados por loja.',
          badgeLabel: 'Mapas',
          highlights: <String>[
            'Brasil por UF',
            'Markers por loja',
            'Troca de visual',
            'Filtro por regiao',
            'Cluster por proximidade',
            'Diagnostico de dados',
          ],
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Tipo do mapa',
          subtitle:
              'Alterne a mesma fonte fake entre pontos, bolhas, bolhas por UF '
              'e icone de loja.',
          child: Semantics(
            label: 'Tipo visual do mapa de vendas por loja',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useCompactLabels = constraints.maxWidth < 520;
                return AppSegmentedControl<AppBrazilStoreSalesMapPreset>(
                  expandToFill: !useCompactLabels,
                  options: AppBrazilStoreSalesMapPreset.values
                      .map(
                        (preset) =>
                            AppSegmentedControlOption<
                              AppBrazilStoreSalesMapPreset
                            >(
                              value: preset,
                              label: preset.demoLabel(
                                l10n,
                                compact: useCompactLabels,
                              ),
                              tooltip: preset.localizedTooltip(l10n),
                            ),
                      )
                      .toList(growable: false),
                  value: selectedMapPreset,
                  onChanged: (preset) {
                    if (preset == selectedMapPreset) {
                      return;
                    }
                    setState(() {
                      _selectedMapPreset = preset;
                      _lastSelectedMapPreset = preset;
                      _eventSummary = null;
                    });
                  },
                );
              },
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppBrazilStoreSalesMapChart(
          key: ValueKey<AppBrazilStoreSalesMapPreset>(selectedMapPreset),
          title: selectedMapPreset.demoTitle,
          subtitle: selectedMapPreset.demoSubtitle,
          points: selectedMapPreset.demoPoints,
          style: selectedMapPreset.demoStyle,
          onStoreTap: (event) {
            setState(() {
              _eventSummary =
                  'Loja: ${event.point.name} | '
                  '${AppBrFormatters.currency(event.point.salesAmount)} | '
                  '${event.point.salesCount} vendas | '
                  'metrica: ${event.metric.key}';
            });
          },
          onStoreClusterTap: (event) {
            setState(() {
              _eventSummary =
                  'Cluster: ${event.points.length} lojas | '
                  '${AppBrFormatters.currency(event.salesAmount)} | '
                  '${event.salesCount} vendas | '
                  'metrica: ${event.metric.key}';
            });
          },
          onStateTap: (event) {
            setState(() {
              _eventSummary =
                  'UF: ${event.regionLabel} | '
                  'receita: ${AppBrFormatters.currency(event.item.salesAmount)} | '
                  'vendas: ${event.item.salesCount}';
            });
          },
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Evento emitido',
          subtitle:
              _eventSummary ??
              'Toque em uma loja ou UF para ver o payload estruturado da demo.',
          child: const SizedBox.shrink(),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppBrazilStoreSalesMapChart(
          title: 'Cenario com valores iguais',
          subtitle:
              'Valida leitura da escala dos markers quando todos os pontos '
              'tem a mesma metrica.',
          points: _equalValueStorePoints,
          style: AppBrazilStoreSalesMapStyle.standard(
            height: 360,
            showStoreDetail: false,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppBrazilStoreSalesMapChart(
          title: 'Estado vazio nacional',
          subtitle:
              'Mantem o mapa do Brasil visivel mesmo quando o recorte ainda '
              'nao retornou lojas.',
          points: <AppBrazilStoreSalesPoint>[],
          style: AppBrazilStoreSalesMapStyle(
            height: 320,
            showStoreDetail: false,
          ),
        ),
      ],
    );
  }
}

AppBrazilStoreSalesMapPreset _lastSelectedMapPreset =
    AppBrazilStoreSalesMapPreset.standard;

extension _BrazilStoreSalesDemoMapPresetX on AppBrazilStoreSalesMapPreset {
  String demoLabel(AppLocalizations l10n, {required bool compact}) =>
      switch (this) {
        AppBrazilStoreSalesMapPreset.standard =>
          compact ? 'Pts' : localizedLabel(l10n),
        AppBrazilStoreSalesMapPreset.bubble => localizedLabel(l10n),
        AppBrazilStoreSalesMapPreset.municipalityBubbles =>
          compact ? 'Mun.' : localizedLabel(l10n),
        AppBrazilStoreSalesMapPreset.stateBubbles =>
          compact ? 'UF' : localizedLabel(l10n),
        AppBrazilStoreSalesMapPreset.storeIcon =>
          compact ? 'Loja' : localizedLabel(l10n),
      };

  String get demoTitle => switch (this) {
    AppBrazilStoreSalesMapPreset.standard => 'Performance de lojas',
    AppBrazilStoreSalesMapPreset.bubble => 'Mapa com bolhas de lojas',
    AppBrazilStoreSalesMapPreset.municipalityBubbles =>
      'Mapa com bolhas por municipio',
    AppBrazilStoreSalesMapPreset.stateBubbles => 'Mapa com bolhas por UF',
    AppBrazilStoreSalesMapPreset.storeIcon => 'Mapa com icone de loja',
  };

  String get demoSubtitle => switch (this) {
    AppBrazilStoreSalesMapPreset.standard =>
      'Dados fake agregados por loja. A consulta SQL real deve entrar '
          'fora do componente visual, entregando esta mesma estrutura.',
    AppBrazilStoreSalesMapPreset.bubble =>
      'Mesmo componente com nomes de estados no GeoJSON e markers em '
          'bolha proporcional, inspirado nos exemplos da Syncfusion.',
    AppBrazilStoreSalesMapPreset.municipalityBubbles =>
      'Agrupa lojas pelo municipio resolvido por IBGE/cidade, somando '
          'receita e vendas em uma bolha por cidade.',
    AppBrazilStoreSalesMapPreset.stateBubbles =>
      'Agrupa a metrica no centroide dos estados, mantendo a consulta '
          'de lojas como fonte dos agregados.',
    AppBrazilStoreSalesMapPreset.storeIcon =>
      'Usa o mesmo overlay geografico, mas troca o ponto por um icone '
          'de loja para leitura operacional.',
  };

  List<AppBrazilStoreSalesPoint> get demoPoints => switch (this) {
    AppBrazilStoreSalesMapPreset.standard => _demoStorePoints,
    AppBrazilStoreSalesMapPreset.bubble => _regionalBubbleStorePoints,
    AppBrazilStoreSalesMapPreset.municipalityBubbles => _demoStorePoints,
    AppBrazilStoreSalesMapPreset.stateBubbles => _demoStorePoints,
    AppBrazilStoreSalesMapPreset.storeIcon => _regionalBubbleStorePoints,
  };

  AppBrazilStoreSalesMapStyle get demoStyle => switch (this) {
    AppBrazilStoreSalesMapPreset.standard =>
      AppBrazilStoreSalesMapPreset.standard.style(
        height: 560,
        enableProximityCluster: true,
      ),
    AppBrazilStoreSalesMapPreset.bubble =>
      AppBrazilStoreSalesMapPreset.bubble.style(
        height: 560,
        showStoreDetail: false,
        showMarkerScaleLegend: false,
      ),
    AppBrazilStoreSalesMapPreset.municipalityBubbles =>
      AppBrazilStoreSalesMapPreset.municipalityBubbles.style(
        height: 560,
        showStoreDetail: false,
        showMarkerScaleLegend: false,
      ),
    AppBrazilStoreSalesMapPreset.stateBubbles =>
      AppBrazilStoreSalesMapPreset.stateBubbles.style(
        height: 560,
        showMarkerScaleLegend: false,
      ),
    AppBrazilStoreSalesMapPreset.storeIcon =>
      AppBrazilStoreSalesMapPreset.storeIcon.style(
        height: 560,
        showStoreDetail: false,
        showMarkerScaleLegend: false,
      ),
  };
}

const List<AppBrazilStoreSalesPoint> _demoStorePoints = [
  AppBrazilStoreSalesPoint(
    id: 'mt-sinop-centro',
    name: 'Loja Sinop Centro',
    uf: 'MT',
    city: 'Sinop',
    latitude: -11.8604,
    longitude: -55.5091,
    salesAmount: 914320.50,
    salesCount: 1284,
    subtitle: 'Varejo fisico',
  ),
  AppBrazilStoreSalesPoint(
    id: 'mt-cuiaba-shopping',
    name: 'Loja Cuiaba Shopping',
    uf: 'MT',
    city: 'Cuiaba',
    latitude: -15.6014,
    longitude: -56.0979,
    salesAmount: 678940.30,
    salesCount: 936,
    subtitle: 'Atendimento regional',
  ),
  AppBrazilStoreSalesPoint(
    id: 'mt-rondonopolis',
    name: 'Loja Rondonopolis',
    uf: 'MT',
    city: 'Rondonopolis',
    latitude: -16.4673,
    longitude: -54.6372,
    salesAmount: 431120.10,
    salesCount: 612,
  ),
  AppBrazilStoreSalesPoint(
    id: 'go-goiania-sul',
    name: 'Loja Goiania Sul',
    uf: 'GO',
    city: 'Goiania',
    latitude: -16.6869,
    longitude: -49.2648,
    salesAmount: 712880.90,
    salesCount: 1018,
  ),
  AppBrazilStoreSalesPoint(
    id: 'df-brasilia',
    name: 'Loja Brasilia',
    uf: 'DF',
    city: 'Brasilia',
    latitude: -15.7939,
    longitude: -47.8828,
    salesAmount: 843210.75,
    salesCount: 1126,
  ),
  AppBrazilStoreSalesPoint(
    id: 'ms-campo-grande',
    name: 'Loja Campo Grande',
    uf: 'MS',
    city: 'Campo Grande',
    latitude: -20.4697,
    longitude: -54.6201,
    salesAmount: 389700,
    salesCount: 544,
  ),
  AppBrazilStoreSalesPoint(
    id: 'sp-paulista',
    name: 'Loja Paulista',
    uf: 'SP',
    city: 'Sao Paulo',
    latitude: -23.5505,
    longitude: -46.6333,
    salesAmount: 1428300.20,
    salesCount: 2158,
  ),
  AppBrazilStoreSalesPoint(
    id: 'sp-paulista-outlet',
    name: 'Loja Paulista Outlet',
    uf: 'SP',
    city: 'Sao Paulo',
    latitude: -23.5505,
    longitude: -46.6333,
    salesAmount: 382120.75,
    salesCount: 518,
  ),
  AppBrazilStoreSalesPoint(
    id: 'sp-pinheiros',
    name: 'Loja Pinheiros',
    uf: 'SP',
    city: 'Sao Paulo',
    latitude: -23.5614,
    longitude: -46.6559,
    salesAmount: 291880.25,
    salesCount: 386,
  ),
  AppBrazilStoreSalesPoint(
    id: 'sp-vila-mariana',
    name: 'Loja Vila Mariana',
    uf: 'SP',
    city: 'Sao Paulo',
    latitude: -23.5892,
    longitude: -46.6346,
    salesAmount: 263450.10,
    salesCount: 341,
  ),
  AppBrazilStoreSalesPoint(
    id: 'rj-centro',
    name: 'Loja Rio Centro',
    uf: 'RJ',
    city: 'Rio de Janeiro',
    latitude: -22.9068,
    longitude: -43.1729,
    salesAmount: 984420.40,
    salesCount: 1488,
  ),
  AppBrazilStoreSalesPoint(
    id: 'mg-savassi',
    name: 'Loja Savassi',
    uf: 'MG',
    city: 'Belo Horizonte',
    latitude: -19.9167,
    longitude: -43.9345,
    salesAmount: 792110,
    salesCount: 1102,
  ),
  AppBrazilStoreSalesPoint(
    id: 'pr-curitiba',
    name: 'Loja Curitiba Batel',
    uf: 'PR',
    city: 'Curitiba',
    latitude: -25.4284,
    longitude: -49.2733,
    salesAmount: 618400.60,
    salesCount: 843,
  ),
  AppBrazilStoreSalesPoint(
    id: 'rs-porto-alegre',
    name: 'Loja Porto Alegre',
    uf: 'RS',
    city: 'Porto Alegre',
    latitude: -30.0346,
    longitude: -51.2177,
    salesAmount: 531990.25,
    salesCount: 731,
  ),
  AppBrazilStoreSalesPoint(
    id: 'ba-salvador',
    name: 'Loja Salvador',
    uf: 'BA',
    city: 'Salvador',
    latitude: -12.9777,
    longitude: -38.5016,
    salesAmount: 573250,
    salesCount: 822,
  ),
  AppBrazilStoreSalesPoint(
    id: 'pe-recife',
    name: 'Loja Recife',
    uf: 'PE',
    city: 'Recife',
    latitude: -8.0476,
    longitude: -34.877,
    salesAmount: 497840.80,
    salesCount: 688,
  ),
  AppBrazilStoreSalesPoint(
    id: 'ce-fortaleza',
    name: 'Loja Fortaleza',
    uf: 'CE',
    city: 'Fortaleza',
    latitude: -3.7319,
    longitude: -38.5267,
    salesAmount: 452700.90,
    salesCount: 604,
  ),
  AppBrazilStoreSalesPoint(
    id: 'am-manaus',
    name: 'Loja Manaus',
    uf: 'AM',
    city: 'Manaus',
    latitude: -3.119,
    longitude: -60.0217,
    salesAmount: 362100,
    salesCount: 459,
  ),
  AppBrazilStoreSalesPoint(
    id: 'pa-belem',
    name: 'Loja Belem',
    uf: 'PA',
    city: 'Belem',
    latitude: -1.4558,
    longitude: -48.4902,
    salesAmount: 418330.35,
    salesCount: 538,
  ),
  AppBrazilStoreSalesPoint(
    id: 'diagnostic-bad-coordinate',
    name: 'Loja com coordenada pendente',
    uf: 'MT',
    city: 'Sinop',
    latitude: 95,
    longitude: -55.5091,
    salesAmount: 127900,
    salesCount: 164,
  ),
];

const List<AppBrazilStoreSalesPoint> _equalValueStorePoints = [
  AppBrazilStoreSalesPoint(
    id: 'eq-mt',
    name: 'Loja Sinop Igual',
    uf: 'MT',
    city: 'Sinop',
    latitude: -11.8604,
    longitude: -55.5091,
    salesAmount: 100000,
    salesCount: 100,
  ),
  AppBrazilStoreSalesPoint(
    id: 'eq-go',
    name: 'Loja Goiania Igual',
    uf: 'GO',
    city: 'Goiania',
    latitude: -16.6869,
    longitude: -49.2648,
    salesAmount: 100000,
    salesCount: 100,
  ),
  AppBrazilStoreSalesPoint(
    id: 'eq-sp',
    name: 'Loja Sao Paulo Igual',
    uf: 'SP',
    city: 'Sao Paulo',
    latitude: -23.5505,
    longitude: -46.6333,
    salesAmount: 100000,
    salesCount: 100,
  ),
];

const List<AppBrazilStoreSalesPoint> _regionalBubbleStorePoints = [
  AppBrazilStoreSalesPoint(
    id: 'bubble-mt',
    name: 'Loja Sinop Centro',
    uf: 'MT',
    city: 'Sinop',
    latitude: -11.8604,
    longitude: -55.5091,
    salesAmount: 914320.50,
    salesCount: 1284,
  ),
  AppBrazilStoreSalesPoint(
    id: 'bubble-go',
    name: 'Loja Goiania Sul',
    uf: 'GO',
    city: 'Goiania',
    latitude: -16.6869,
    longitude: -49.2648,
    salesAmount: 712880.90,
    salesCount: 1018,
  ),
  AppBrazilStoreSalesPoint(
    id: 'bubble-sp',
    name: 'Loja Paulista',
    uf: 'SP',
    city: 'Sao Paulo',
    latitude: -23.5505,
    longitude: -46.6333,
    salesAmount: 1428300.20,
    salesCount: 2158,
  ),
  AppBrazilStoreSalesPoint(
    id: 'bubble-rj',
    name: 'Loja Rio Centro',
    uf: 'RJ',
    city: 'Rio de Janeiro',
    latitude: -22.9068,
    longitude: -43.1729,
    salesAmount: 984420.40,
    salesCount: 1488,
  ),
  AppBrazilStoreSalesPoint(
    id: 'bubble-ba',
    name: 'Loja Salvador',
    uf: 'BA',
    city: 'Salvador',
    latitude: -12.9777,
    longitude: -38.5016,
    salesAmount: 573250,
    salesCount: 822,
  ),
  AppBrazilStoreSalesPoint(
    id: 'bubble-am',
    name: 'Loja Manaus',
    uf: 'AM',
    city: 'Manaus',
    latitude: -3.119,
    longitude: -60.0217,
    salesAmount: 362100,
    salesCount: 459,
  ),
];
