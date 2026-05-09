enum AppLocationLookupType {
  geoPoint,
  ibgeMunicipalityCode,
  cep,
  cityUf,
  capitalUf,
  uf,
}

enum AppLocationPrecision {
  exact,
  cep,
  city,
  stateCentroid,
}

enum AppLocationSource {
  provided,
  cache,
  geocodingProvider,
  staticBrazilMunicipalityCentroid,
  staticBrazilStateCentroid,
}

class AppGeoPoint {
  const AppGeoPoint({
    required this.latitude,
    required this.longitude,
  });

  factory AppGeoPoint.fromJson(Map<String, Object?> json) {
    return AppGeoPoint(
      latitude: _readRequiredDouble(json, 'latitude'),
      longitude: _readRequiredDouble(json, 'longitude'),
    );
  }

  final double latitude;
  final double longitude;

  bool get isValid {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class AppLocationLookupInput {
  const AppLocationLookupInput.geoPoint({
    required AppGeoPoint this.geoPoint,
  }) : type = AppLocationLookupType.geoPoint,
       ibgeMunicipalityCode = null,
       cep = null,
       city = null,
       uf = null;

  const AppLocationLookupInput.cep({
    required String this.cep,
  }) : type = AppLocationLookupType.cep,
       geoPoint = null,
       ibgeMunicipalityCode = null,
       city = null,
       uf = null;

  const AppLocationLookupInput.ibgeMunicipalityCode({
    required String this.ibgeMunicipalityCode,
  }) : type = AppLocationLookupType.ibgeMunicipalityCode,
       geoPoint = null,
       cep = null,
       city = null,
       uf = null;

  const AppLocationLookupInput.cityUf({
    required String this.city,
    required String this.uf,
  }) : type = AppLocationLookupType.cityUf,
       geoPoint = null,
       ibgeMunicipalityCode = null,
       cep = null;

  const AppLocationLookupInput.capitalUf({
    required String this.uf,
  }) : type = AppLocationLookupType.capitalUf,
       geoPoint = null,
       ibgeMunicipalityCode = null,
       cep = null,
       city = null;

  const AppLocationLookupInput.uf({
    required String this.uf,
  }) : type = AppLocationLookupType.uf,
       geoPoint = null,
       ibgeMunicipalityCode = null,
       cep = null,
       city = null;

  final AppLocationLookupType type;
  final AppGeoPoint? geoPoint;
  final String? ibgeMunicipalityCode;
  final String? cep;
  final String? city;
  final String? uf;
}

class AppResolvedLocation {
  const AppResolvedLocation({
    required this.point,
    required this.precision,
    required this.source,
    required this.cacheKey,
    this.metadata = const <String, Object?>{},
    this.label,
    this.resolvedAt,
  });

  factory AppResolvedLocation.fromJson(Map<String, Object?> json) {
    return AppResolvedLocation(
      point: AppGeoPoint.fromJson(_readRequiredMap(json, 'point')),
      precision: _readEnum(
        json,
        'precision',
        AppLocationPrecision.values,
      ),
      source: _readEnum(json, 'source', AppLocationSource.values),
      cacheKey: _readRequiredString(json, 'cacheKey'),
      metadata: _readOptionalStringObjectMap(json, 'metadata'),
      label: json['label'] as String?,
      resolvedAt: switch (json['resolvedAt']) {
        final String value when value.isNotEmpty => DateTime.parse(value),
        _ => null,
      },
    );
  }

  final AppGeoPoint point;
  final AppLocationPrecision precision;
  final AppLocationSource source;
  final String cacheKey;
  final Map<String, Object?> metadata;
  final String? label;
  final DateTime? resolvedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'point': point.toJson(),
      'precision': precision.name,
      'source': source.name,
      'cacheKey': cacheKey,
      'metadata': metadata,
      'label': label,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  AppResolvedLocation copyWith({
    AppGeoPoint? point,
    AppLocationPrecision? precision,
    AppLocationSource? source,
    String? cacheKey,
    Map<String, Object?>? metadata,
    String? label,
    DateTime? resolvedAt,
  }) {
    return AppResolvedLocation(
      point: point ?? this.point,
      precision: precision ?? this.precision,
      source: source ?? this.source,
      cacheKey: cacheKey ?? this.cacheKey,
      metadata: metadata ?? this.metadata,
      label: label ?? this.label,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

double _readRequiredDouble(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is num) {
    return value.toDouble();
  }

  throw FormatException('Location field "$key" must be numeric.');
}

String _readRequiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }

  throw FormatException('Location field "$key" must be a non-empty string.');
}

Map<String, Object?> _readRequiredMap(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value is Map<String, Object?>) {
    return value;
  }

  throw FormatException('Location field "$key" must be an object.');
}

Map<String, Object?> _readOptionalStringObjectMap(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value == null) {
    return const <String, Object?>{};
  }

  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  throw FormatException('Location field "$key" must be an object.');
}

T _readEnum<T extends Enum>(
  Map<String, Object?> json,
  String key,
  List<T> values,
) {
  final value = _readRequiredString(json, key);
  for (final candidate in values) {
    if (candidate.name == value) {
      return candidate;
    }
  }

  throw FormatException('Location field "$key" has invalid value "$value".');
}
