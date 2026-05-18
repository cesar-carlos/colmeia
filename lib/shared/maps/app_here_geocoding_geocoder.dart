import 'package:colmeia/shared/maps/app_here_geocoding_candidate_matcher.dart';
import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:dio/dio.dart';

class AppHereGeocodingGeocoder implements AppLocationGeocoder {
  AppHereGeocodingGeocoder({
    required Dio dio,
    required String apiKey,
    String endpointUrl = _defaultEndpointUrl,
  }) : _dio = dio,
       _apiKey = apiKey,
       _endpointUrl = endpointUrl;

  static const String _defaultEndpointUrl =
      'https://geocode.search.hereapi.com/v1/geocode';

  final Dio _dio;
  final String _apiKey;
  final String _endpointUrl;

  @override
  String get providerId => 'here_geocoding';

  @override
  bool get isExternal => true;

  @override
  int get maxConcurrentRequests => 2;

  @override
  Future<AppLocationGeocoderResult> resolve(
    AppLocationLookupInput input,
  ) async {
    if (_apiKey.trim().isEmpty) {
      return const AppLocationGeocoderResult.unsupported();
    }

    final params = _queryParametersFor(input);
    if (params == null) {
      return const AppLocationGeocoderResult.unsupported();
    }

    try {
      final response = await _dio.get<Object?>(
        _endpointUrl,
        queryParameters: params,
      );
      final data = response.data;
      if (data is! Map<Object?, Object?>) {
        return const AppLocationGeocoderResult.transientFailure(
          message: 'HERE geocoding returned an invalid payload.',
        );
      }

      final items = data['items'];
      if (items is! List || items.isEmpty) {
        return const AppLocationGeocoderResult.notFound();
      }

      final candidates = items
          .whereType<Map<Object?, Object?>>()
          .map((item) => _candidateFromItem(Map<Object?, Object?>.from(item)))
          .whereType<AppHereGeocodingCandidate>()
          .toList(growable: false);
      final selected = AppHereGeocodingCandidateMatcher.selectBest(
        input: input,
        candidates: candidates,
      );
      if (selected == null) {
        return const AppLocationGeocoderResult.notFound();
      }

      return AppLocationGeocoderResult.resolved(
        AppResolvedLocation(
          point: selected.point,
          precision: _precisionFor(selected.resultType, input),
          source: AppLocationSource.geocodingProvider,
          cacheKey: '',
          label: selected.label ?? selected.title,
          details: AppResolvedAddressDetails(
            city: selected.city,
            uf: AppLocationLookupNormalizer.normalizeUf(selected.uf),
            district: selected.district,
            cep: AppLocationLookupNormalizer.normalizeCep(selected.postalCode),
            countryCode: AppLocationLookupNormalizer.normalizeCountryCodeLoose(
              selected.countryCode,
            ),
          ),
          metadata: <String, Object?>{
            if (selected.countryCode != null)
              'providerCountryCode': selected.countryCode,
            if (selected.resultType != null)
              'providerResultType': selected.resultType,
          },
        ),
      );
    } on DioException catch (error) {
      return AppLocationGeocoderResult.transientFailure(
        message: error.message,
        retryAfter: _retryAfterFrom(error.response?.headers),
      );
    } on Exception catch (error) {
      return AppLocationGeocoderResult.transientFailure(
        message: error.toString(),
      );
    }
  }

  Map<String, Object?>? _queryParametersFor(AppLocationLookupInput input) {
    switch (input.type) {
      case AppLocationLookupType.cep:
        final cep = AppLocationLookupNormalizer.normalizeCep(input.cep);
        if (cep == null) {
          return null;
        }
        return <String, Object?>{
          'apiKey': _apiKey,
          'limit': 5,
          'types': 'address',
          'q': '$cep, Brasil',
          'qq': 'postalCode=$cep;country=Brazil',
        };
      case AppLocationLookupType.streetAddress:
        final address = input.postalAddress;
        final freeForm = address?.toFreeFormQuery();
        if (address == null || freeForm == null || freeForm.trim().isEmpty) {
          return null;
        }
        final street = _trimmed(address.street);
        final number = _trimmed(address.number);
        final district = _trimmed(address.district);
        final city = _trimmed(address.city);
        final uf = _trimmed(address.uf);
        final cep = AppLocationLookupNormalizer.normalizeCep(address.cep);
        final qqParts = <String>[
          if (street != null) 'street=$street',
          if (number != null) 'houseNumber=$number',
          if (district != null) 'district=$district',
          if (city != null) 'city=$city',
          if (uf != null) 'state=$uf',
          if (cep != null) 'postalCode=$cep',
        ];
        return <String, Object?>{
          'apiKey': _apiKey,
          'limit': 5,
          'types': 'address',
          'q': freeForm,
          if (qqParts.isNotEmpty) 'qq': qqParts.join(';'),
        };
      case AppLocationLookupType.geoPoint ||
          AppLocationLookupType.ibgeMunicipalityCode ||
          AppLocationLookupType.cityUf ||
          AppLocationLookupType.capitalUf ||
          AppLocationLookupType.uf:
        return null;
    }
  }

  AppHereGeocodingCandidate? _candidateFromItem(Map<Object?, Object?> item) {
    final itemMap = Map<String, Object?>.from(item);
    final position = itemMap['position'];
    if (position is! Map) {
      return null;
    }

    final latValue = position['lat'];
    final lngValue = position['lng'];
    if (latValue is! num || lngValue is! num) {
      return null;
    }

    final point = AppGeoPoint(
      latitude: latValue.toDouble(),
      longitude: lngValue.toDouble(),
    );
    if (!point.isValid) {
      return null;
    }

    final addressMap = switch (itemMap['address']) {
      final Map<String, Object?> value => value,
      final Map<Object?, Object?> value => Map<String, Object?>.from(value),
      _ => const <String, Object?>{},
    };

    return AppHereGeocodingCandidate(
      point: point,
      resultType: _readNonEmptyString(itemMap['resultType']),
      label: _readNonEmptyString(addressMap['label']),
      title: _readNonEmptyString(itemMap['title']),
      city: _readNonEmptyString(addressMap['city']),
      uf: _readNonEmptyString(addressMap['stateCode']),
      district: _readNonEmptyString(addressMap['district']),
      postalCode: _readNonEmptyString(addressMap['postalCode']),
      countryCode: _readNonEmptyString(addressMap['countryCode']),
    );
  }

  AppLocationPrecision _precisionFor(
    String? resultType,
    AppLocationLookupInput input,
  ) {
    if (input.type == AppLocationLookupType.cep ||
        resultType == 'postalCodePoint') {
      return AppLocationPrecision.cep;
    }

    return switch (resultType) {
      'houseNumber' || 'street' || 'intersection' => AppLocationPrecision.exact,
      'administrativeArea' => AppLocationPrecision.stateCentroid,
      _ => AppLocationPrecision.city,
    };
  }

  Duration? _retryAfterFrom(Headers? headers) {
    final values = headers?.map['retry-after'];
    if (values == null || values.isEmpty) {
      return null;
    }

    final raw = values.first.trim();
    final seconds = int.tryParse(raw);
    if (seconds != null && seconds >= 0) {
      return Duration(seconds: seconds);
    }
    final date = DateTime.tryParse(raw);
    if (date == null) {
      return null;
    }
    final wait = date.toUtc().difference(DateTime.now().toUtc());
    return wait.isNegative ? Duration.zero : wait;
  }

  String? _readNonEmptyString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  String? _trimmed(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
