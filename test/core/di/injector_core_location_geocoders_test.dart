import 'package:colmeia/core/di/injector_core.dart';
import 'package:colmeia/shared/maps/app_geocoding_plugin_geocoder.dart';
import 'package:colmeia/shared/maps/app_here_geocoding_geocoder.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildPlatformLocationGeocoders', () {
    final dio = Dio();

    test('builds mobile chain with plugin and optional HERE', () {
      final geocoders = buildPlatformLocationGeocoders(
        isWeb: false,
        targetPlatform: TargetPlatform.android,
        dio: dio,
        hereApiKey: 'test-key',
      );

      expect(geocoders, hasLength(2));
      expect(geocoders.first, isA<AppGeocodingPluginGeocoder>());
      expect(geocoders.last, isA<AppHereGeocodingGeocoder>());
    });

    test('builds desktop chain with HERE only', () {
      final geocoders = buildPlatformLocationGeocoders(
        isWeb: false,
        targetPlatform: TargetPlatform.windows,
        dio: dio,
        hereApiKey: 'test-key',
      );

      expect(geocoders, hasLength(1));
      expect(geocoders.single, isA<AppHereGeocodingGeocoder>());
    });

    test('builds web chain without external address providers', () {
      final geocoders = buildPlatformLocationGeocoders(
        isWeb: true,
        targetPlatform: TargetPlatform.android,
        dio: dio,
        hereApiKey: 'test-key',
      );

      expect(geocoders, isEmpty);
    });
  });
}
