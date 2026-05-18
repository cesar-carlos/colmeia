import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Static Brazil map metadata embedded in the app.
///
/// These values are build-time data. They should stay in memory/consts instead
/// of going through persistent feature caches.
abstract final class AppBrazilMapStaticData {
  static const String brazilUfGeoJsonAssetPath =
      'assets/maps/brazil_ufs.geojson';

  static const AppMapDefinition brazilUfMapDefinition = AppMapDefinition.asset(
    assetPath: brazilUfGeoJsonAssetPath,
    shapeDataField: 'UF',
    regionLevel: AppMapRegionLevel.state,
  );

  static Uint8List? _brazilUfGeoJsonBytes;

  /// Raw GeoJSON bytes for [brazilUfGeoJsonAssetPath] after [precacheBrazilUfGeoJsonAsset].
  static Uint8List? get brazilUfGeoJsonBytesOrNull => _brazilUfGeoJsonBytes;

  /// Loads [brazilUfGeoJsonAssetPath] into memory so the map engine can use an
  /// in-memory GeoJSON buffer on first mount. Idempotent.
  ///
  /// Returns `true` only when this invocation populated [brazilUfGeoJsonBytesOrNull]
  /// (so callers can rebuild once to switch the map to an in-memory shape source). Returns
  /// `false` when bytes were already cached or another concurrent call finished first.
  static Future<bool> precacheBrazilUfGeoJsonAsset() async {
    if (_brazilUfGeoJsonBytes != null) {
      return false;
    }
    final data = await rootBundle.load(brazilUfGeoJsonAssetPath);
    if (_brazilUfGeoJsonBytes != null) {
      return false;
    }
    _brazilUfGeoJsonBytes = Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    return true;
  }

  @visibleForTesting
  static void resetBrazilUfGeoJsonMemoryCacheForTests() {
    _brazilUfGeoJsonBytes = null;
  }

  static const AppMapViewport brazilViewport = AppMapViewport(
    centerLatitude: -14.235,
    centerLongitude: -51.9253,
    zoomLevel: 1.45,
  );

  static const Map<String, AppMapViewport> regionViewports = {
    'NO': AppMapViewport(
      centerLatitude: -3.7,
      centerLongitude: -61.9,
      zoomLevel: 2.35,
    ),
    'NE': AppMapViewport(
      centerLatitude: -8.9,
      centerLongitude: -39.6,
      zoomLevel: 2.85,
    ),
    'CO': AppMapViewport(
      centerLatitude: -15.6,
      centerLongitude: -55.5,
      zoomLevel: 2.85,
    ),
    'SE': AppMapViewport(
      centerLatitude: -20.3,
      centerLongitude: -44.8,
      zoomLevel: 3,
    ),
    'SU': AppMapViewport(
      centerLatitude: -28,
      centerLongitude: -51,
      zoomLevel: 3.25,
    ),
  };

  static const List<String> ufCodes = [
    'AC',
    'AL',
    'AM',
    'AP',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MG',
    'MS',
    'MT',
    'PA',
    'PB',
    'PE',
    'PI',
    'PR',
    'RJ',
    'RN',
    'RO',
    'RR',
    'RS',
    'SC',
    'SE',
    'SP',
    'TO',
  ];

  static const Map<String, AppBrazilStateCentroid> stateCentroidsByUf = {
    'AC': AppBrazilStateCentroid(latitude: -9.02, longitude: -70.81),
    'AL': AppBrazilStateCentroid(latitude: -9.57, longitude: -36.78),
    'AM': AppBrazilStateCentroid(latitude: -3.47, longitude: -65.10),
    'AP': AppBrazilStateCentroid(latitude: 1.41, longitude: -51.77),
    'BA': AppBrazilStateCentroid(latitude: -12.96, longitude: -41.70),
    'CE': AppBrazilStateCentroid(latitude: -5.20, longitude: -39.53),
    'DF': AppBrazilStateCentroid(latitude: -15.83, longitude: -47.86),
    'ES': AppBrazilStateCentroid(latitude: -19.19, longitude: -40.34),
    'GO': AppBrazilStateCentroid(latitude: -15.98, longitude: -49.86),
    'MA': AppBrazilStateCentroid(latitude: -5.42, longitude: -45.44),
    'MG': AppBrazilStateCentroid(latitude: -18.10, longitude: -44.38),
    'MS': AppBrazilStateCentroid(latitude: -20.51, longitude: -54.54),
    'MT': AppBrazilStateCentroid(latitude: -12.64, longitude: -55.42),
    'PA': AppBrazilStateCentroid(latitude: -3.79, longitude: -52.48),
    'PB': AppBrazilStateCentroid(latitude: -7.28, longitude: -36.72),
    'PE': AppBrazilStateCentroid(latitude: -8.38, longitude: -37.86),
    'PI': AppBrazilStateCentroid(latitude: -6.60, longitude: -42.28),
    'PR': AppBrazilStateCentroid(latitude: -24.89, longitude: -51.55),
    'RJ': AppBrazilStateCentroid(latitude: -22.25, longitude: -42.66),
    'RN': AppBrazilStateCentroid(latitude: -5.81, longitude: -36.59),
    'RO': AppBrazilStateCentroid(latitude: -10.83, longitude: -63.34),
    'RR': AppBrazilStateCentroid(latitude: 1.99, longitude: -61.33),
    'RS': AppBrazilStateCentroid(latitude: -30.17, longitude: -53.50),
    'SC': AppBrazilStateCentroid(latitude: -27.45, longitude: -50.95),
    'SE': AppBrazilStateCentroid(latitude: -10.57, longitude: -37.45),
    'SP': AppBrazilStateCentroid(latitude: -22.19, longitude: -48.79),
    'TO': AppBrazilStateCentroid(latitude: -10.25, longitude: -48.25),
  };

  static const Map<String, String> stateNamesByUf = {
    'AC': 'Acre',
    'AL': 'Alagoas',
    'AM': 'Amazonas',
    'AP': 'Amapa',
    'BA': 'Bahia',
    'CE': 'Ceara',
    'DF': 'Distrito Federal',
    'ES': 'Espirito Santo',
    'GO': 'Goias',
    'MA': 'Maranhao',
    'MG': 'Minas Gerais',
    'MS': 'Mato Grosso do Sul',
    'MT': 'Mato Grosso',
    'PA': 'Para',
    'PB': 'Paraiba',
    'PE': 'Pernambuco',
    'PI': 'Piaui',
    'PR': 'Parana',
    'RJ': 'Rio de Janeiro',
    'RN': 'Rio Grande do Norte',
    'RO': 'Rondonia',
    'RR': 'Roraima',
    'RS': 'Rio Grande do Sul',
    'SC': 'Santa Catarina',
    'SE': 'Sergipe',
    'SP': 'Sao Paulo',
    'TO': 'Tocantins',
  };

  static const Map<String, String> regionKeysByUf = {
    'AC': 'NO',
    'AL': 'NE',
    'AM': 'NO',
    'AP': 'NO',
    'BA': 'NE',
    'CE': 'NE',
    'DF': 'CO',
    'ES': 'SE',
    'GO': 'CO',
    'MA': 'NE',
    'MG': 'SE',
    'MS': 'CO',
    'MT': 'CO',
    'PA': 'NO',
    'PB': 'NE',
    'PE': 'NE',
    'PI': 'NE',
    'PR': 'SU',
    'RJ': 'SE',
    'RN': 'NE',
    'RO': 'NO',
    'RR': 'NO',
    'RS': 'SU',
    'SC': 'SU',
    'SE': 'NE',
    'SP': 'SE',
    'TO': 'NO',
  };

  static String stateNameForUf(String uf) {
    final normalizedUf = uf.trim().toUpperCase();
    return stateNamesByUf[normalizedUf] ?? normalizedUf;
  }

  static String? regionKeyForUf(String uf) {
    return regionKeysByUf[uf.trim().toUpperCase()];
  }
}

class AppBrazilStateCentroid {
  const AppBrazilStateCentroid({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}
