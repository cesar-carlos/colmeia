import 'dart:convert';
import 'dart:typed_data';

import 'package:colmeia/shared/maps/app_here_geocoding_geocoder.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestHttpClientAdapter implements HttpClientAdapter {
  _TestHttpClientAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }
}

void main() {
  group('AppHereGeocodingGeocoder', () {
    test('resolves street address and sends structured query params', () async {
      late RequestOptions capturedOptions;
      final dio = Dio()
        ..httpClientAdapter = _TestHttpClientAdapter((options) async {
          capturedOptions = options;
          return ResponseBody.fromString(
            jsonEncode(<String, Object?>{
              'items': <Object?>[
                <String, Object?>{
                  'title': 'Rua das Flores 123',
                  'resultType': 'houseNumber',
                  'position': <String, double>{
                    'lat': -11.8604,
                    'lng': -55.5091,
                  },
                  'address': <String, Object?>{
                    'label': 'Rua das Flores, 123 - Sinop, MT',
                    'city': 'Sinop',
                    'stateCode': 'MT',
                    'district': 'Centro',
                    'postalCode': '78550005',
                    'countryCode': 'BRA',
                  },
                },
              ],
            }),
            200,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        });
      final geocoder = AppHereGeocodingGeocoder(
        dio: dio,
        apiKey: 'test-key',
      );

      final result = await geocoder.resolve(
        const AppLocationLookupInput.streetAddress(
          postalAddress: AppPostalAddress(
            street: 'Rua das Flores',
            number: '123',
            district: 'Centro',
            city: 'Sinop',
            uf: 'MT',
            cep: '78550005',
          ),
        ),
      );

      expect(capturedOptions.queryParameters['apiKey'], 'test-key');
      expect(
        capturedOptions.queryParameters['q'],
        'Rua das Flores, 123, Centro, Sinop, MT, 78550005, BR',
      );
      expect(
        capturedOptions.queryParameters['qq'],
        'street=Rua das Flores;houseNumber=123;district=Centro;city=Sinop;state=MT;postalCode=78550005',
      );
      expect(result.type, AppLocationGeocoderResultType.resolved);
      expect(result.location?.precision, AppLocationPrecision.exact);
      expect(result.location?.details?.city, 'Sinop');
      expect(result.location?.details?.uf, 'MT');
      expect(result.location?.details?.cep, '78550005');
    });

    test('returns notFound when HERE returns no items', () async {
      final dio = Dio()
        ..httpClientAdapter = _TestHttpClientAdapter((_) async {
          return ResponseBody.fromString(
            jsonEncode(<String, Object?>{
              'items': const <Object?>[],
            }),
            200,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        });
      final geocoder = AppHereGeocodingGeocoder(
        dio: dio,
        apiKey: 'test-key',
      );

      final result = await geocoder.resolve(
        const AppLocationLookupInput.cep(cep: '01001-000'),
      );

      expect(result.type, AppLocationGeocoderResultType.notFound);
    });

    test('maps Dio retry-after into transient failure', () async {
      final dio = Dio()
        ..httpClientAdapter = _TestHttpClientAdapter((options) async {
          throw DioException(
            requestOptions: options,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 429,
              headers: Headers.fromMap(<String, List<String>>{
                'retry-after': <String>['30'],
              }),
            ),
            type: DioExceptionType.badResponse,
          );
        });
      final geocoder = AppHereGeocodingGeocoder(
        dio: dio,
        apiKey: 'test-key',
      );

      final result = await geocoder.resolve(
        const AppLocationLookupInput.cep(cep: '01001-000'),
      );

      expect(result.type, AppLocationGeocoderResultType.transientFailure);
      expect(result.retryAfter, const Duration(seconds: 30));
    });

    test('returns unsupported when api key is empty', () async {
      final geocoder = AppHereGeocodingGeocoder(
        dio: Dio(),
        apiKey: '   ',
      );

      final result = await geocoder.resolve(
        const AppLocationLookupInput.cep(cep: '01001-000'),
      );

      expect(result.type, AppLocationGeocoderResultType.unsupported);
    });
  });
}
