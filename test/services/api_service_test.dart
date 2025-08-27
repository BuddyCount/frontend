import 'package:flutter_test/flutter_test.dart';
import 'package:buddycount_frontend/services/api_service.dart';

void main() {
  group('ApiService Tests', () {
    group('Base URL Configuration', () {
      test('should have correct base URL', () {
        expect(ApiService.baseUrl, 'https://api.buddycount.duckdns.org');
      });

      test('should have valid URL format', () {
        final uri = Uri.parse(ApiService.baseUrl);
        expect(uri.scheme, 'https');
        expect(uri.host, 'api.buddycount.duckdns.org');
      });
    });

    group('Service Structure', () {
      test('should have required configuration', () {
        expect(ApiService.baseUrl, isA<String>());
        expect(ApiService.baseUrl.isNotEmpty, isTrue);
        expect(ApiService.baseUrl.startsWith('https://'), isTrue);
      });

      test('should have valid domain format', () {
        final domain = Uri.parse(ApiService.baseUrl).host;
        expect(domain.split('.').length, greaterThanOrEqualTo(2));
        expect(domain.contains('duckdns.org'), isTrue);
      });

      test('should use secure HTTPS protocol', () {
        final uri = Uri.parse(ApiService.baseUrl);
        expect(uri.scheme, 'https');
        expect(uri.port, 443); // Default HTTPS port
      });
    });

    group('URL Validation', () {
      test('should parse base URL correctly', () {
        final uri = Uri.parse(ApiService.baseUrl);
        expect(uri.scheme, 'https');
        expect(uri.host, 'api.buddycount.duckdns.org');
        expect(uri.path, '');
        expect(uri.queryParameters, isEmpty);
      });

      test('should have no query parameters by default.', () {
        final uri = Uri.parse(ApiService.baseUrl);
        expect(uri.queryParameters, isEmpty);
        expect(uri.fragment, isEmpty);
      });
    });
  });
}
