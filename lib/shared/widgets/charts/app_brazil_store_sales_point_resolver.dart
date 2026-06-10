import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';

class AppBrazilStoreSalesPointSource {
  const AppBrazilStoreSalesPointSource({
    required this.id,
    required this.name,
    required this.salesAmount,
    required this.salesCount,
    this.uf,
    this.city,
    this.latitude,
    this.longitude,
    this.cep,
    this.ibgeMunicipalityCode,
    this.preferCapitalFallback = false,
    this.allowUfFallback = true,
    this.fantasyName,
    this.branchName,
    this.companyCode,
    this.branchCode,
    this.agentName,
    this.salesDataLoading = false,
    this.salesDataUnavailable = false,
    this.salesDataStatusLabel,
    this.subtitle,
    this.payload,
  });

  final String id;
  final String name;
  final double salesAmount;
  final int salesCount;
  final String? uf;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? cep;
  final String? ibgeMunicipalityCode;
  final bool preferCapitalFallback;
  final bool allowUfFallback;
  final String? fantasyName;
  final String? branchName;
  final int? companyCode;
  final int? branchCode;
  final String? agentName;
  final bool salesDataLoading;
  final bool salesDataUnavailable;
  final String? salesDataStatusLabel;
  final String? subtitle;
  final Object? payload;
}

class AppBrazilStoreSalesPointResolver {
  const AppBrazilStoreSalesPointResolver({
    required AppLocationResolver locationResolver,
  }) : _locationResolver = locationResolver;

  final AppLocationResolver _locationResolver;

  Future<AppBrazilStoreSalesPoint?> resolve(
    AppBrazilStoreSalesPointSource source,
  ) async {
    final resolved = await resolveWithDetails(source);
    return resolved?.point;
  }

  Future<AppBrazilStoreSalesResolvedPoint?> resolveWithDetails(
    AppBrazilStoreSalesPointSource source,
  ) {
    return _resolveWithDetails(
      source,
      lookupInputsFor: _lookupInputsFor,
    );
  }

  /// Resolves coordinates from SQL municipality signals only (IBGE code and
  /// city/UF). Skips CEP and broader fallbacks so the live map can paint fast
  /// before the full geolocation pass runs.
  Future<AppBrazilStoreSalesResolvedPoint?> resolveSqlMunicipalityWithDetails(
    AppBrazilStoreSalesPointSource source,
  ) {
    return _resolveWithDetails(
      source,
      lookupInputsFor: _sqlMunicipalityLookupInputsFor,
    );
  }

  Future<AppBrazilStoreSalesResolvedPoint?> _resolveWithDetails(
    AppBrazilStoreSalesPointSource source, {
    required List<AppLocationLookupInput> Function(
      AppBrazilStoreSalesPointSource source,
    )
    lookupInputsFor,
    Map<String, Future<_ResolvedLocationLookup?>>? locationCache,
  }) async {
    final lookup = await _resolveLocationLookup(
      source,
      locationCache: locationCache,
      lookupInputsFor: lookupInputsFor,
    );
    if (lookup == null) {
      return null;
    }

    final uf = _resolveUf(source, lookup.location);
    if (uf == null) {
      return null;
    }
    final municipalityCode =
        AppLocationLookupNormalizer.normalizeIbgeMunicipalityCode(
          source.ibgeMunicipalityCode,
        );

    return AppBrazilStoreSalesResolvedPoint(
      point: AppBrazilStoreSalesPoint(
        id: source.id,
        name: source.name,
        uf: uf,
        latitude: lookup.location.point.latitude,
        longitude: lookup.location.point.longitude,
        salesAmount: source.salesAmount,
        salesCount: source.salesCount,
        municipalityCode: municipalityCode,
        city: _resolveCity(source, lookup.location),
        fantasyName: source.fantasyName,
        branchName: source.branchName,
        companyCode: source.companyCode,
        branchCode: source.branchCode,
        agentName: source.agentName,
        salesDataLoading: source.salesDataLoading,
        salesDataUnavailable: source.salesDataUnavailable,
        salesDataStatusLabel: source.salesDataStatusLabel,
        locationResolution: _resolutionFor(lookup.lookupType),
        subtitle: source.subtitle,
        payload: source.payload,
      ),
      location: lookup.location,
      lookupType: lookup.lookupType,
    );
  }

  Future<List<AppBrazilStoreSalesPoint>> resolveAll(
    Iterable<AppBrazilStoreSalesPointSource> sources,
  ) async {
    final points = <AppBrazilStoreSalesPoint>[];
    for (final source in sources) {
      final resolved = await resolveWithDetails(source);
      if (resolved != null) {
        points.add(resolved.point);
      }
    }

    return points;
  }

  Future<List<AppBrazilStoreSalesResolvedPoint>>
  resolveAllSqlMunicipalityWithDetails(
    Iterable<AppBrazilStoreSalesPointSource> sources, {
    int maxConcurrent = 1,
  }) async {
    return _resolveAllWithDetails(
      sources,
      maxConcurrent: maxConcurrent,
      lookupInputsFor: _sqlMunicipalityLookupInputsFor,
    );
  }

  Future<List<AppBrazilStoreSalesResolvedPoint>> resolveAllWithDetails(
    Iterable<AppBrazilStoreSalesPointSource> sources, {
    int maxConcurrent = 1,
  }) async {
    return _resolveAllWithDetails(
      sources,
      maxConcurrent: maxConcurrent,
      lookupInputsFor: _lookupInputsFor,
    );
  }

  Future<List<AppBrazilStoreSalesResolvedPoint>> _resolveAllWithDetails(
    Iterable<AppBrazilStoreSalesPointSource> sources, {
    required int maxConcurrent,
    required List<AppLocationLookupInput> Function(
      AppBrazilStoreSalesPointSource source,
    )
    lookupInputsFor,
  }) async {
    final sourceList = sources.toList(growable: false);
    if (sourceList.isEmpty) {
      return const <AppBrazilStoreSalesResolvedPoint>[];
    }

    final locationCache = <String, Future<_ResolvedLocationLookup?>>{};
    if (maxConcurrent <= 1 || sourceList.length == 1) {
      final points = <AppBrazilStoreSalesResolvedPoint>[];
      for (final source in sourceList) {
        final resolved = await _resolveWithDetails(
          source,
          locationCache: locationCache,
          lookupInputsFor: lookupInputsFor,
        );
        if (resolved != null) {
          points.add(resolved);
        }
      }

      return points;
    }

    final results = List<AppBrazilStoreSalesResolvedPoint?>.filled(
      sourceList.length,
      null,
    );
    final workerCount = maxConcurrent < sourceList.length
        ? maxConcurrent
        : sourceList.length;
    var nextIndex = 0;

    Future<void> runWorker() async {
      while (true) {
        final index = nextIndex;
        if (index >= sourceList.length) {
          return;
        }
        nextIndex += 1;

        final source = sourceList[index];
        final resolved = await _resolveWithDetails(
          source,
          locationCache: locationCache,
          lookupInputsFor: lookupInputsFor,
        );
        if (resolved != null) {
          results[index] = resolved;
        }
      }
    }

    await Future.wait<void>(
      List<Future<void>>.generate(workerCount, (_) => runWorker()),
    );

    return results.whereType<AppBrazilStoreSalesResolvedPoint>().toList(
      growable: false,
    );
  }

  Future<_ResolvedLocationLookup?> _resolveLocationLookup(
    AppBrazilStoreSalesPointSource source, {
    required List<AppLocationLookupInput> Function(
      AppBrazilStoreSalesPointSource source,
    )
    lookupInputsFor,
    Map<String, Future<_ResolvedLocationLookup?>>? locationCache,
  }) async {
    for (final input in lookupInputsFor(source)) {
      final cacheKey = _lookupInputCacheKey(input);
      final resolved = cacheKey == null || locationCache == null
          ? await _resolveLookupInput(input)
          : await locationCache.putIfAbsent(
              cacheKey,
              () => _resolveLookupInput(input),
            );
      if (resolved != null) {
        return resolved;
      }
    }

    return null;
  }

  Future<_ResolvedLocationLookup?> _resolveLookupInput(
    AppLocationLookupInput input,
  ) async {
    final result = await _locationResolver.resolve(input);
    final outcome = result.getOrNull();
    if (outcome is! AppLocationResolutionResolved) {
      return null;
    }

    final resolved = outcome.location;
    if (!resolved.point.isValid) {
      return null;
    }

    return _ResolvedLocationLookup(
      location: resolved,
      lookupType: input.type,
    );
  }

  String? _lookupInputCacheKey(AppLocationLookupInput input) {
    if (input.type == AppLocationLookupType.geoPoint) {
      final point = input.geoPoint;
      return point == null
          ? null
          : 'provided:${point.latitude}:${point.longitude}';
    }

    return AppLocationLookupNormalizer.cacheKeyFor(input);
  }

  List<AppLocationLookupInput> _sqlMunicipalityLookupInputsFor(
    AppBrazilStoreSalesPointSource source,
  ) {
    final inputs = <AppLocationLookupInput>[];
    final latitude = source.latitude;
    final longitude = source.longitude;
    final uf = AppLocationLookupNormalizer.normalizeUf(source.uf);
    if (latitude != null &&
        longitude != null &&
        uf != null &&
        AppGeoPoint(latitude: latitude, longitude: longitude).isValid) {
      inputs.add(
        AppLocationLookupInput.geoPoint(
          geoPoint: AppGeoPoint(latitude: latitude, longitude: longitude),
        ),
      );
    }

    final ibgeCode = AppLocationLookupNormalizer.normalizeIbgeMunicipalityCode(
      source.ibgeMunicipalityCode,
    );
    if (ibgeCode != null) {
      inputs.add(
        AppLocationLookupInput.ibgeMunicipalityCode(
          ibgeMunicipalityCode: ibgeCode,
        ),
      );
    }

    final city = AppLocationLookupNormalizer.normalizeCity(source.city);
    if (city != null && uf != null) {
      inputs.add(AppLocationLookupInput.cityUf(city: source.city!, uf: uf));
    }

    return inputs;
  }

  List<AppLocationLookupInput> _lookupInputsFor(
    AppBrazilStoreSalesPointSource source,
  ) {
    final inputs = <AppLocationLookupInput>[];
    final latitude = source.latitude;
    final longitude = source.longitude;
    final uf = AppLocationLookupNormalizer.normalizeUf(source.uf);
    if (latitude != null &&
        longitude != null &&
        uf != null &&
        AppGeoPoint(latitude: latitude, longitude: longitude).isValid) {
      inputs.add(
        AppLocationLookupInput.geoPoint(
          geoPoint: AppGeoPoint(latitude: latitude, longitude: longitude),
        ),
      );
    }

    final ibgeCode = AppLocationLookupNormalizer.normalizeIbgeMunicipalityCode(
      source.ibgeMunicipalityCode,
    );
    if (ibgeCode != null) {
      inputs.add(
        AppLocationLookupInput.ibgeMunicipalityCode(
          ibgeMunicipalityCode: ibgeCode,
        ),
      );
    }

    final cep = AppLocationLookupNormalizer.normalizeCep(source.cep);
    if (cep != null) {
      inputs.add(AppLocationLookupInput.cep(cep: cep));
    }

    final city = AppLocationLookupNormalizer.normalizeCity(source.city);
    if (city != null && uf != null) {
      inputs.add(AppLocationLookupInput.cityUf(city: source.city!, uf: uf));
    }

    if (source.preferCapitalFallback && uf != null) {
      inputs.add(AppLocationLookupInput.capitalUf(uf: uf));
    }

    if (source.allowUfFallback && uf != null) {
      inputs.add(AppLocationLookupInput.uf(uf: uf));
    }

    return inputs;
  }

  String? _resolveUf(
    AppBrazilStoreSalesPointSource source,
    AppResolvedLocation location,
  ) {
    final detailsUf = AppLocationLookupNormalizer.normalizeUf(
      location.details?.uf,
    );
    if (detailsUf != null) {
      return detailsUf;
    }

    return AppLocationLookupNormalizer.normalizeUf(source.uf);
  }

  String? _resolveCity(
    AppBrazilStoreSalesPointSource source,
    AppResolvedLocation location,
  ) {
    final city = source.city?.trim();
    if (city != null && city.isNotEmpty) {
      return city;
    }

    final detailsCity = location.details?.city?.trim();
    if (detailsCity != null && detailsCity.isNotEmpty) {
      return detailsCity;
    }

    return null;
  }

  AppBrazilStoreSalesLocationResolution? _resolutionFor(
    AppLocationLookupType? lookupType,
  ) {
    return switch (lookupType) {
      AppLocationLookupType.geoPoint =>
        AppBrazilStoreSalesLocationResolution.providedGeoPoint,
      AppLocationLookupType.streetAddress => null,
      AppLocationLookupType.ibgeMunicipalityCode =>
        AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode,
      AppLocationLookupType.cep => AppBrazilStoreSalesLocationResolution.cep,
      AppLocationLookupType.cityUf =>
        AppBrazilStoreSalesLocationResolution.cityUf,
      AppLocationLookupType.capitalUf =>
        AppBrazilStoreSalesLocationResolution.capitalUf,
      AppLocationLookupType.uf => AppBrazilStoreSalesLocationResolution.stateUf,
      null => null,
    };
  }
}

class AppBrazilStoreSalesResolvedPoint {
  const AppBrazilStoreSalesResolvedPoint({
    required this.point,
    required this.location,
    required this.lookupType,
  });

  final AppBrazilStoreSalesPoint point;
  final AppResolvedLocation location;
  final AppLocationLookupType? lookupType;
}

class _ResolvedLocationLookup {
  const _ResolvedLocationLookup({
    required this.location,
    required this.lookupType,
  });

  final AppResolvedLocation location;
  final AppLocationLookupType lookupType;
}
