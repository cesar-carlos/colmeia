enum AppLocationLookupType {
  geoPoint,
  streetAddress,
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

enum AppLocationCacheEntryStatus {
  resolved,
  notFound,
}

enum AppLocationGeocoderResultType {
  resolved,
  notFound,
  unsupported,
  transientFailure,
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

class AppPostalAddress {
  const AppPostalAddress({
    this.street,
    this.number,
    this.district,
    this.city,
    this.uf,
    this.cep,
    this.countryCode = 'BR',
  });

  final String? street;
  final String? number;
  final String? district;
  final String? city;
  final String? uf;
  final String? cep;
  final String countryCode;

  bool get isEmpty {
    return !_hasText(street) &&
        !_hasText(number) &&
        !_hasText(district) &&
        !_hasText(city) &&
        !_hasText(uf) &&
        !_hasText(cep);
  }

  String? toFreeFormQuery() {
    final streetLine = <String>[
      if (_hasText(street)) street!.trim(),
      if (_hasText(number)) number!.trim(),
    ].join(', ');
    final parts = <String>[
      if (streetLine.trim().isNotEmpty) streetLine,
      if (_hasText(district)) district!.trim(),
      if (_hasText(city)) city!.trim(),
      if (_hasText(uf)) uf!.trim(),
      if (_hasText(cep)) cep!.trim(),
      if (countryCode.trim().isNotEmpty) countryCode.trim(),
    ];
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(', ');
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}

class AppResolvedAddressDetails {
  const AppResolvedAddressDetails({
    this.city,
    this.uf,
    this.district,
    this.cep,
    this.countryCode,
  });

  factory AppResolvedAddressDetails.fromJson(Map<String, Object?> json) {
    return AppResolvedAddressDetails(
      city: json['city'] as String?,
      uf: json['uf'] as String?,
      district: json['district'] as String?,
      cep: json['cep'] as String?,
      countryCode: json['countryCode'] as String?,
    );
  }

  final String? city;
  final String? uf;
  final String? district;
  final String? cep;
  final String? countryCode;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'city': city,
      'uf': uf,
      'district': district,
      'cep': cep,
      'countryCode': countryCode,
    };
  }

  AppResolvedAddressDetails copyWith({
    String? city,
    String? uf,
    String? district,
    String? cep,
    String? countryCode,
  }) {
    return AppResolvedAddressDetails(
      city: city ?? this.city,
      uf: uf ?? this.uf,
      district: district ?? this.district,
      cep: cep ?? this.cep,
      countryCode: countryCode ?? this.countryCode,
    );
  }
}

class AppLocationLookupInput {
  const AppLocationLookupInput.geoPoint({
    required AppGeoPoint this.geoPoint,
  }) : type = AppLocationLookupType.geoPoint,
       postalAddress = null,
       ibgeMunicipalityCode = null,
       cep = null,
       city = null,
       uf = null;

  const AppLocationLookupInput.streetAddress({
    required AppPostalAddress this.postalAddress,
  }) : type = AppLocationLookupType.streetAddress,
       geoPoint = null,
       ibgeMunicipalityCode = null,
       cep = null,
       city = null,
       uf = null;

  const AppLocationLookupInput.cep({
    required String this.cep,
  }) : type = AppLocationLookupType.cep,
       geoPoint = null,
       postalAddress = null,
       ibgeMunicipalityCode = null,
       city = null,
       uf = null;

  const AppLocationLookupInput.ibgeMunicipalityCode({
    required String this.ibgeMunicipalityCode,
  }) : type = AppLocationLookupType.ibgeMunicipalityCode,
       geoPoint = null,
       postalAddress = null,
       cep = null,
       city = null,
       uf = null;

  const AppLocationLookupInput.cityUf({
    required String this.city,
    required String this.uf,
  }) : type = AppLocationLookupType.cityUf,
       geoPoint = null,
       postalAddress = null,
       ibgeMunicipalityCode = null,
       cep = null;

  const AppLocationLookupInput.capitalUf({
    required String this.uf,
  }) : type = AppLocationLookupType.capitalUf,
       geoPoint = null,
       postalAddress = null,
       ibgeMunicipalityCode = null,
       cep = null,
       city = null;

  const AppLocationLookupInput.uf({
    required String this.uf,
  }) : type = AppLocationLookupType.uf,
       geoPoint = null,
       postalAddress = null,
       ibgeMunicipalityCode = null,
       cep = null,
       city = null;

  final AppLocationLookupType type;
  final AppGeoPoint? geoPoint;
  final AppPostalAddress? postalAddress;
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
    this.details,
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
      details: switch (json['details']) {
        final Map<String, Object?> value => AppResolvedAddressDetails.fromJson(
          value,
        ),
        final Map<Object?, Object?> value => AppResolvedAddressDetails.fromJson(
          Map<String, Object?>.from(value),
        ),
        _ => null,
      },
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
  final AppResolvedAddressDetails? details;
  final Map<String, Object?> metadata;
  final String? label;
  final DateTime? resolvedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'point': point.toJson(),
      'precision': precision.name,
      'source': source.name,
      'cacheKey': cacheKey,
      'details': details?.toJson(),
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
    AppResolvedAddressDetails? details,
    Map<String, Object?>? metadata,
    String? label,
    DateTime? resolvedAt,
  }) {
    return AppResolvedLocation(
      point: point ?? this.point,
      precision: precision ?? this.precision,
      source: source ?? this.source,
      cacheKey: cacheKey ?? this.cacheKey,
      details: details ?? this.details,
      metadata: metadata ?? this.metadata,
      label: label ?? this.label,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

class AppLocationCacheEntry {
  const AppLocationCacheEntry({
    required this.schemaVersion,
    required this.status,
    required this.cacheKey,
    required this.providerId,
    required this.createdAt,
    required this.expiresAt,
    this.location,
  });

  factory AppLocationCacheEntry.fromJson(Map<String, Object?> json) {
    return AppLocationCacheEntry(
      schemaVersion: _readRequiredInt(json, 'schemaVersion'),
      status: _readEnum(
        json,
        'status',
        AppLocationCacheEntryStatus.values,
      ),
      cacheKey: _readRequiredString(json, 'cacheKey'),
      providerId: _readRequiredString(json, 'providerId'),
      createdAt: DateTime.parse(_readRequiredString(json, 'createdAt')),
      expiresAt: DateTime.parse(_readRequiredString(json, 'expiresAt')),
      location: switch (json['location']) {
        final Map<String, Object?> value => AppResolvedLocation.fromJson(value),
        final Map<Object?, Object?> value => AppResolvedLocation.fromJson(
          Map<String, Object?>.from(value),
        ),
        _ => null,
      },
    );
  }

  final int schemaVersion;
  final AppLocationCacheEntryStatus status;
  final String cacheKey;
  final String providerId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final AppResolvedLocation? location;

  bool isExpired(DateTime now) => !expiresAt.isAfter(now);

  bool get isResolved => status == AppLocationCacheEntryStatus.resolved;

  bool get isNotFound => status == AppLocationCacheEntryStatus.notFound;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'status': status.name,
      'cacheKey': cacheKey,
      'providerId': providerId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'location': location?.toJson(),
    };
  }
}

sealed class AppLocationResolutionOutcome {
  const AppLocationResolutionOutcome();

  const factory AppLocationResolutionOutcome.resolved(
    AppResolvedLocation location,
  ) = AppLocationResolutionResolved;

  const factory AppLocationResolutionOutcome.notFound() =
      AppLocationResolutionNotFound;
}

final class AppLocationResolutionResolved extends AppLocationResolutionOutcome {
  const AppLocationResolutionResolved(this.location);

  final AppResolvedLocation location;
}

final class AppLocationResolutionNotFound extends AppLocationResolutionOutcome {
  const AppLocationResolutionNotFound();
}

class AppLocationCachePurgeSummary {
  const AppLocationCachePurgeSummary({
    required this.scannedEntries,
    required this.removedExpiredEntries,
    required this.removedOrphanedIndexEntries,
    required this.remainingIndexedEntries,
  });

  final int scannedEntries;
  final int removedExpiredEntries;
  final int removedOrphanedIndexEntries;
  final int remainingIndexedEntries;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'scannedEntries': scannedEntries,
      'removedExpiredEntries': removedExpiredEntries,
      'removedOrphanedIndexEntries': removedOrphanedIndexEntries,
      'remainingIndexedEntries': remainingIndexedEntries,
    };
  }
}

class AppLocationGeocoderResult {
  const AppLocationGeocoderResult._({
    required this.type,
    this.location,
    this.message,
    this.retryAfter,
  });

  const AppLocationGeocoderResult.resolved(AppResolvedLocation location)
    : this._(
        type: AppLocationGeocoderResultType.resolved,
        location: location,
      );

  const AppLocationGeocoderResult.notFound({String? message})
    : this._(
        type: AppLocationGeocoderResultType.notFound,
        message: message,
      );

  const AppLocationGeocoderResult.unsupported({String? message})
    : this._(
        type: AppLocationGeocoderResultType.unsupported,
        message: message,
      );

  const AppLocationGeocoderResult.transientFailure({
    String? message,
    Duration? retryAfter,
  }) : this._(
         type: AppLocationGeocoderResultType.transientFailure,
         message: message,
         retryAfter: retryAfter,
       );

  final AppLocationGeocoderResultType type;
  final AppResolvedLocation? location;
  final String? message;
  final Duration? retryAfter;

  bool get isResolved => type == AppLocationGeocoderResultType.resolved;
}

double _readRequiredDouble(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is num) {
    return value.toDouble();
  }

  throw FormatException('Location field "$key" must be numeric.');
}

int _readRequiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }

  throw FormatException('Location field "$key" must be an integer.');
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
