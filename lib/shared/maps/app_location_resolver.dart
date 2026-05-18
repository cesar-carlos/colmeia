import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolution_observer.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:result_dart/result_dart.dart';

abstract interface class AppLocationGeocoder {
  String get providerId;

  bool get isExternal => false;

  int get maxConcurrentRequests => 1;

  Future<AppLocationGeocoderResult> resolve(AppLocationLookupInput input);
}

class AppLocationResolver {
  AppLocationResolver({
    required AppLocationGeocodeCache cache,
    AppLocationGeocoder? geocoder,
    List<AppLocationGeocoder> geocoders = const <AppLocationGeocoder>[],
    AppLocationResolutionObserver observer =
        const AppLocationResolutionObserver(),
    DateTime Function()? now,
  }) : _cache = cache,
       _geocoder = geocoder,
       _geocoders = geocoders,
       _observer = observer,
       _now = now;

  final AppLocationGeocodeCache _cache;
  final AppLocationGeocoder? _geocoder;
  final List<AppLocationGeocoder> _geocoders;
  final AppLocationResolutionObserver _observer;
  final DateTime Function()? _now;
  final Map<String, Future<AppResult<AppLocationResolutionOutcome>>>
  _inflightByKey = <String, Future<AppResult<AppLocationResolutionOutcome>>>{};
  final Map<String, _AppLocationProviderGate> _providerGates =
      <String, _AppLocationProviderGate>{};

  Future<AppResult<AppLocationResolutionOutcome>> resolve(
    AppLocationLookupInput input,
  ) async {
    final providedPoint = input.geoPoint;
    if (input.type == AppLocationLookupType.geoPoint &&
        providedPoint != null &&
        providedPoint.isValid) {
      return Success<AppLocationResolutionOutcome, AppFailure>(
        AppLocationResolutionOutcome.resolved(
          AppResolvedLocation(
            point: providedPoint,
            precision: AppLocationPrecision.exact,
            source: AppLocationSource.provided,
            cacheKey: 'provided_geo_point',
            resolvedAt: _resolveNow(),
          ),
        ),
      );
    }

    final cacheKey = AppLocationLookupNormalizer.cacheKeyFor(input);
    if (cacheKey == null) {
      return const Success<AppLocationResolutionOutcome, AppFailure>(
        AppLocationResolutionOutcome.notFound(),
      );
    }

    final inflight = _inflightByKey[cacheKey];
    if (inflight != null) {
      return inflight;
    }

    final completer = Completer<AppResult<AppLocationResolutionOutcome>>();
    _inflightByKey[cacheKey] = completer.future;
    try {
      final result = await _resolveInternal(input, cacheKey);
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      return result;
    } on Object catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
      rethrow;
    } finally {
      if (identical(_inflightByKey[cacheKey], completer.future)) {
        unawaited(_inflightByKey.remove(cacheKey));
      }
    }
  }

  Future<AppResult<AppLocationResolutionOutcome>> _resolveInternal(
    AppLocationLookupInput input,
    String cacheKey,
  ) async {
    try {
      if (_usesPersistentCache(input.type)) {
        final cached = await _cache.readEntry(cacheKey, now: _resolveNow());
        if (cached != null) {
          if (cached.isResolved && cached.location != null) {
            _emitEvent(
              'cache_hit_resolved',
              input,
              providerId: cached.providerId,
              fromCache: true,
              resolutionPrecision: cached.location!.precision,
            );
            return Success<AppLocationResolutionOutcome, AppFailure>(
              AppLocationResolutionOutcome.resolved(
                cached.location!.copyWith(
                  source: AppLocationSource.cache,
                ),
              ),
            );
          }
          if (cached.isNotFound) {
            _emitEvent(
              'cache_hit_not_found',
              input,
              providerId: cached.providerId,
              fromCache: true,
            );
            return const Success<AppLocationResolutionOutcome, AppFailure>(
              AppLocationResolutionOutcome.notFound(),
            );
          }
        }
      }

      final geocoderResult = await _resolveWithGeocoders(input, cacheKey);
      if (geocoderResult.location != null) {
        final resolved = geocoderResult.location!;
        if (_usesPersistentCache(input.type) && _shouldPersist(resolved)) {
          await _cache.writeResolved(
            resolved,
            lookupType: input.type,
            providerId: geocoderResult.providerId ?? 'unknown',
            createdAt: resolved.resolvedAt ?? _resolveNow(),
          );
          _emitEvent(
            'cache_write_resolved',
            input,
            providerId: geocoderResult.providerId,
            resolutionPrecision: resolved.precision,
          );
        }
        return Success<AppLocationResolutionOutcome, AppFailure>(
          AppLocationResolutionOutcome.resolved(resolved),
        );
      }

      if (input.type == AppLocationLookupType.uf) {
        final centroid = _resolveBrazilStateCentroid(input.uf, cacheKey);
        if (centroid != null) {
          return Success<AppLocationResolutionOutcome, AppFailure>(
            AppLocationResolutionOutcome.resolved(centroid),
          );
        }
      }

      if (geocoderResult.hadTransientFailure) {
        return Failure<AppLocationResolutionOutcome, AppFailure>(
          NetworkFailure(
            message:
                'Location geocoding provider failed while resolving ${input.type.name}.',
            userMessage:
                'Nao foi possivel consultar a geolocalizacao agora. Tente novamente.',
            retryAfter: geocoderResult.retryAfter,
            context: <String, Object?>{
              'operation': 'AppLocationResolver.resolve',
              ..._observerContextForInput(
                input,
                providerId: geocoderResult.providerId,
                retryAfter: geocoderResult.retryAfter,
              ),
            },
          ),
        );
      }

      if (_usesPersistentCache(input.type) && geocoderResult.hadNotFound) {
        await _cache.writeNotFound(
          cacheKey: cacheKey,
          lookupType: input.type,
          providerId: geocoderResult.providerId ?? 'unknown',
          createdAt: _resolveNow(),
        );
        _emitEvent(
          'cache_write_not_found',
          input,
          providerId: geocoderResult.providerId,
        );
        return const Success<AppLocationResolutionOutcome, AppFailure>(
          AppLocationResolutionOutcome.notFound(),
        );
      }

      if (geocoderResult.hadUnsupported) {
        return Failure<AppLocationResolutionOutcome, AppFailure>(
          UnknownFailure(
            message:
                'Geocoding for ${input.type.name} is not supported on this platform.',
            userMessage:
                'A geolocalizacao por endereco nao esta disponivel nesta plataforma.',
            context: <String, Object?>{
              'operation': 'AppLocationResolver.resolve',
              ..._observerContextForInput(
                input,
                providerId: geocoderResult.providerId,
              ),
              'reason': 'unsupported',
            },
          ),
        );
      }

      return const Success<AppLocationResolutionOutcome, AppFailure>(
        AppLocationResolutionOutcome.notFound(),
      );
    } on AppFailure catch (failure) {
      return Failure<AppLocationResolutionOutcome, AppFailure>(failure);
    } on Object catch (error, stackTrace) {
      return Failure<AppLocationResolutionOutcome, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage:
              'Unexpected location geocoding failure while resolving ${input.type.name}.',
          fallbackUserMessage:
              'Nao foi possivel resolver a geolocalizacao solicitada.',
          context: <String, Object?>{
            'operation': 'AppLocationResolver.resolve',
            ..._observerContextForInput(input),
          },
        ),
      );
    }
  }

  Future<_ResolveWithGeocodersResult> _resolveWithGeocoders(
    AppLocationLookupInput input,
    String cacheKey,
  ) async {
    final geocoders = <AppLocationGeocoder>[
      ..._geocoders,
      ...?_geocoder == null ? null : <AppLocationGeocoder>[_geocoder],
    ];
    var hadNotFound = false;
    var hadUnsupported = false;
    var hadTransientFailure = false;
    Duration? retryAfter;
    String? providerId;

    for (final geocoder in geocoders) {
      final result = await _runThroughGate(
        geocoder,
        () => geocoder.resolve(input),
      );
      switch (result.type) {
        case AppLocationGeocoderResultType.resolved:
          final location = result.location;
          if (location != null && location.point.isValid) {
            final resolved = location.copyWith(
              cacheKey: cacheKey,
              resolvedAt: location.resolvedAt ?? _resolveNow(),
            );
            _emitEvent(
              'provider_resolved',
              input,
              providerId: geocoder.providerId,
              resolutionPrecision: resolved.precision,
            );
            return _ResolveWithGeocodersResult(
              location: resolved,
              providerId: geocoder.providerId,
            );
          }
        case AppLocationGeocoderResultType.notFound:
          hadNotFound = true;
          providerId = geocoder.providerId;
          _emitEvent(
            'provider_not_found',
            input,
            providerId: geocoder.providerId,
          );
        case AppLocationGeocoderResultType.unsupported:
          hadUnsupported = true;
          providerId ??= geocoder.providerId;
          _emitEvent(
            'provider_unsupported',
            input,
            providerId: geocoder.providerId,
          );
        case AppLocationGeocoderResultType.transientFailure:
          hadTransientFailure = true;
          providerId = geocoder.providerId;
          retryAfter ??= result.retryAfter;
          _emitEvent(
            'provider_transient_failure',
            input,
            providerId: geocoder.providerId,
            retryAfter: result.retryAfter,
          );
      }
    }

    return _ResolveWithGeocodersResult(
      hadNotFound: hadNotFound,
      hadUnsupported: hadUnsupported || geocoders.isEmpty,
      hadTransientFailure: hadTransientFailure,
      retryAfter: retryAfter,
      providerId: providerId,
    );
  }

  Future<AppLocationGeocoderResult> _runThroughGate(
    AppLocationGeocoder geocoder,
    Future<AppLocationGeocoderResult> Function() action,
  ) {
    if (!geocoder.isExternal) {
      return action();
    }

    final gate = _providerGates.putIfAbsent(
      geocoder.providerId,
      () => _AppLocationProviderGate(geocoder.maxConcurrentRequests),
    );
    return gate.run(action);
  }

  DateTime _resolveNow() {
    return (_now ?? () => DateTime.now().toUtc())();
  }

  AppResolvedLocation? _resolveBrazilStateCentroid(
    String? uf,
    String cacheKey,
  ) {
    final normalizedUf = AppLocationLookupNormalizer.normalizeUf(uf);
    if (normalizedUf == null) {
      return null;
    }

    final centroid = AppBrazilMapStaticData.stateCentroidsByUf[normalizedUf];
    if (centroid == null) {
      return null;
    }

    return AppResolvedLocation(
      point: AppGeoPoint(
        latitude: centroid.latitude,
        longitude: centroid.longitude,
      ),
      precision: AppLocationPrecision.stateCentroid,
      source: AppLocationSource.staticBrazilStateCentroid,
      cacheKey: cacheKey,
      label: AppBrazilMapStaticData.stateNameForUf(normalizedUf),
      details: AppResolvedAddressDetails(
        uf: normalizedUf,
        countryCode: 'BR',
      ),
      resolvedAt: _resolveNow(),
    );
  }

  void _emitEvent(
    String event,
    AppLocationLookupInput input, {
    String? providerId,
    bool? fromCache,
    Duration? retryAfter,
    AppLocationPrecision? resolutionPrecision,
  }) {
    _observer.onEvent(
      event: event,
      context: _observerContextForInput(
        input,
        providerId: providerId,
        fromCache: fromCache,
        retryAfter: retryAfter,
        resolutionPrecision: resolutionPrecision,
      ),
    );
  }

  Map<String, Object?> _observerContextForInput(
    AppLocationLookupInput input, {
    String? providerId,
    bool? fromCache,
    Duration? retryAfter,
    AppLocationPrecision? resolutionPrecision,
  }) {
    final address = input.postalAddress;
    return <String, Object?>{
      'lookupType': input.type.name,
      ...?providerId == null
          ? null
          : <String, Object?>{'providerId': providerId},
      ...?fromCache == null ? null : <String, Object?>{'fromCache': fromCache},
      if (retryAfter != null) 'retryAfterMs': retryAfter.inMilliseconds,
      if (resolutionPrecision != null)
        'resolutionPrecision': resolutionPrecision.name,
      'hasCep': switch (input.type) {
        AppLocationLookupType.cep => true,
        AppLocationLookupType.streetAddress =>
          AppLocationLookupNormalizer.normalizeCep(address?.cep) != null,
        _ => false,
      },
      'hasCity': switch (input.type) {
        AppLocationLookupType.cityUf =>
          AppLocationLookupNormalizer.normalizeCity(input.city) != null,
        AppLocationLookupType.streetAddress =>
          AppLocationLookupNormalizer.normalizeCity(address?.city) != null,
        _ => false,
      },
      'hasUf': switch (input.type) {
        AppLocationLookupType.cityUf ||
        AppLocationLookupType.capitalUf ||
        AppLocationLookupType.uf =>
          AppLocationLookupNormalizer.normalizeUf(input.uf) != null,
        AppLocationLookupType.streetAddress =>
          AppLocationLookupNormalizer.normalizeUf(address?.uf) != null,
        _ => false,
      },
      'hasStreet':
          input.type == AppLocationLookupType.streetAddress &&
          address?.street?.trim().isNotEmpty == true,
      'hasNumber':
          input.type == AppLocationLookupType.streetAddress &&
          address?.number?.trim().isNotEmpty == true,
    };
  }

  bool _usesPersistentCache(AppLocationLookupType type) {
    return switch (type) {
      AppLocationLookupType.streetAddress || AppLocationLookupType.cep => true,
      AppLocationLookupType.geoPoint ||
      AppLocationLookupType.ibgeMunicipalityCode ||
      AppLocationLookupType.cityUf ||
      AppLocationLookupType.capitalUf ||
      AppLocationLookupType.uf => false,
    };
  }

  bool _shouldPersist(AppResolvedLocation location) {
    return switch (location.source) {
      AppLocationSource.staticBrazilMunicipalityCentroid ||
      AppLocationSource.staticBrazilStateCentroid ||
      AppLocationSource.provided ||
      AppLocationSource.cache => false,
      AppLocationSource.geocodingProvider => true,
    };
  }
}

class _ResolveWithGeocodersResult {
  const _ResolveWithGeocodersResult({
    this.location,
    this.providerId,
    this.hadNotFound = false,
    this.hadUnsupported = false,
    this.hadTransientFailure = false,
    this.retryAfter,
  });

  final AppResolvedLocation? location;
  final String? providerId;
  final bool hadNotFound;
  final bool hadUnsupported;
  final bool hadTransientFailure;
  final Duration? retryAfter;
}

class _AppLocationProviderGate {
  _AppLocationProviderGate(this._maxConcurrent);

  final int _maxConcurrent;
  int _active = 0;
  final List<Completer<void>> _waiters = <Completer<void>>[];

  Future<T> run<T>(Future<T> Function() action) async {
    await _acquire();
    try {
      return await action();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() {
    if (_active < _maxConcurrent) {
      _active += 1;
      return Future<void>.value();
    }

    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
      return;
    }

    if (_active > 0) {
      _active -= 1;
    }
  }
}
