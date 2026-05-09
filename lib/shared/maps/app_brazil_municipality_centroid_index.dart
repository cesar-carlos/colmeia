import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:flutter/services.dart';

class AppBrazilMunicipalityCentroid {
  const AppBrazilMunicipalityCentroid({
    required this.ibgeCode,
    required this.name,
    required this.normalizedName,
    required this.ufCode,
    required this.uf,
    required this.stateName,
    required this.region,
    required this.isCapital,
    required this.longitude,
    required this.latitude,
    this.siafiId,
    this.ddd,
    this.timezone,
  });

  final String ibgeCode;
  final String name;
  final String normalizedName;
  final int ufCode;
  final String uf;
  final String stateName;
  final String region;
  final bool isCapital;
  final double longitude;
  final double latitude;
  final String? siafiId;
  final String? ddd;
  final String? timezone;

  AppGeoPoint get point {
    return AppGeoPoint(latitude: latitude, longitude: longitude);
  }
}

class AppBrazilMunicipalityCentroidIndex {
  AppBrazilMunicipalityCentroidIndex._({
    required Map<String, AppBrazilMunicipalityCentroid> byIbgeCode,
    required Map<String, AppBrazilMunicipalityCentroid> byCityUf,
    required Map<String, AppBrazilMunicipalityCentroid> capitalByUf,
  }) : _byIbgeCode = byIbgeCode,
       _byCityUf = byCityUf,
       _capitalByUf = capitalByUf;

  factory AppBrazilMunicipalityCentroidIndex.parse(String content) {
    final lines = content
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      throw const FormatException('Municipality centroid CSV is empty.');
    }

    final header = lines.first.trim();
    if (header != expectedHeader) {
      throw FormatException(
        'Invalid municipality centroid CSV header: "$header".',
      );
    }

    final byIbgeCode = <String, AppBrazilMunicipalityCentroid>{};
    final byCityUf = <String, AppBrazilMunicipalityCentroid>{};
    final capitalByUf = <String, AppBrazilMunicipalityCentroid>{};
    for (var index = 1; index < lines.length; index += 1) {
      final centroid = _parseLine(lines[index], index + 1);
      if (centroid == null) {
        continue;
      }

      byIbgeCode[centroid.ibgeCode] = centroid;
      byCityUf.putIfAbsent(
        _cityUfKey(centroid.normalizedName, centroid.uf),
        () => centroid,
      );
      if (centroid.isCapital) {
        capitalByUf.putIfAbsent(centroid.uf, () => centroid);
      }
    }

    return AppBrazilMunicipalityCentroidIndex._(
      byIbgeCode: Map.unmodifiable(byIbgeCode),
      byCityUf: Map.unmodifiable(byCityUf),
      capitalByUf: Map.unmodifiable(capitalByUf),
    );
  }

  static const String assetPath = 'assets/maps/brazil_municipios_centroids.csv';
  static const String sourceUrl =
      'https://github.com/kelvins/municipios-brasileiros';
  static const String sourceMunicipalitiesCsvUrl =
      'https://raw.githubusercontent.com/kelvins/municipios-brasileiros/'
      'main/csv/municipios.csv';
  static const String sourceStatesCsvUrl =
      'https://raw.githubusercontent.com/kelvins/municipios-brasileiros/'
      'main/csv/estados.csv';
  static const String sourceLicense = 'MIT';
  static const String sourceLicenseAssetPath =
      'assets/maps/brazil_municipios_centroids.LICENSE';
  static const String expectedHeader =
      'codigo_ibge;nome;codigo_uf;uf;estado;regiao;capital;latitude;'
      'longitude;siafi_id;ddd;fuso_horario';

  static Future<AppBrazilMunicipalityCentroidIndex> loadFromAsset({
    AssetBundle? bundle,
  }) async {
    final resolvedBundle = bundle ?? rootBundle;
    final content = await resolvedBundle.loadString(assetPath);
    return AppBrazilMunicipalityCentroidIndex.parse(content);
  }

  final Map<String, AppBrazilMunicipalityCentroid> _byIbgeCode;
  final Map<String, AppBrazilMunicipalityCentroid> _byCityUf;
  final Map<String, AppBrazilMunicipalityCentroid> _capitalByUf;

  int get length => _byIbgeCode.length;

  Iterable<AppBrazilMunicipalityCentroid> get values => _byIbgeCode.values;

  int get capitalCount => _capitalByUf.length;

  Set<String> get ufs => Set<String>.unmodifiable(
    values.map((centroid) => centroid.uf),
  );

  Set<String> get regions => Set<String>.unmodifiable(
    values.map((centroid) => centroid.region),
  );

  AppBrazilMunicipalityCentroid? lookupByIbgeCode(String? ibgeCode) {
    final normalizedCode =
        AppLocationLookupNormalizer.normalizeIbgeMunicipalityCode(ibgeCode);
    if (normalizedCode == null) {
      return null;
    }

    return _byIbgeCode[normalizedCode];
  }

  AppBrazilMunicipalityCentroid? lookupByCityUf({
    required String? city,
    required String? uf,
  }) {
    final normalizedCity = AppLocationLookupNormalizer.normalizeCity(city);
    final normalizedUf = AppLocationLookupNormalizer.normalizeUf(uf);
    if (normalizedCity == null || normalizedUf == null) {
      return null;
    }

    return _byCityUf[_cityUfKey(normalizedCity, normalizedUf)];
  }

  AppBrazilMunicipalityCentroid? lookupCapitalByUf(String? uf) {
    final normalizedUf = AppLocationLookupNormalizer.normalizeUf(uf);
    if (normalizedUf == null) {
      return null;
    }

    return _capitalByUf[normalizedUf];
  }

  static AppBrazilMunicipalityCentroid? _parseLine(
    String line,
    int lineNumber,
  ) {
    final parts = line.split(';');
    if (parts.length != 12) {
      throw FormatException(
        'Invalid municipality centroid CSV line $lineNumber.',
      );
    }

    final ibgeCode = AppLocationLookupNormalizer.normalizeIbgeMunicipalityCode(
      parts[0],
    );
    final name = parts[1].trim();
    final normalizedName = AppLocationLookupNormalizer.normalizeCity(name);
    final ufCode = int.tryParse(parts[2].trim());
    final uf = AppLocationLookupNormalizer.normalizeUf(parts[3]);
    final stateName = parts[4].trim();
    final region = parts[5].trim();
    final isCapital = _parseCapitalFlag(parts[6]);
    final latitude = double.tryParse(parts[7].trim());
    final longitude = double.tryParse(parts[8].trim());
    final siafiId = _nullIfEmpty(parts[9]);
    final ddd = _nullIfEmpty(parts[10]);
    final timezone = _nullIfEmpty(parts[11]);
    if (ibgeCode == null ||
        name.isEmpty ||
        normalizedName == null ||
        ufCode == null ||
        uf == null ||
        stateName.isEmpty ||
        region.isEmpty ||
        isCapital == null ||
        longitude == null ||
        latitude == null) {
      return null;
    }

    final point = AppGeoPoint(latitude: latitude, longitude: longitude);
    if (!point.isValid) {
      return null;
    }

    return AppBrazilMunicipalityCentroid(
      ibgeCode: ibgeCode,
      name: name,
      normalizedName: normalizedName,
      ufCode: ufCode,
      uf: uf,
      stateName: stateName,
      region: region,
      isCapital: isCapital,
      longitude: longitude,
      latitude: latitude,
      siafiId: siafiId,
      ddd: ddd,
      timezone: timezone,
    );
  }

  static String _cityUfKey(String normalizedCity, String uf) {
    return '${normalizedCity}_$uf';
  }

  static bool? _parseCapitalFlag(String value) {
    return switch (value.trim()) {
      '0' => false,
      '1' => true,
      _ => null,
    };
  }

  static String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
