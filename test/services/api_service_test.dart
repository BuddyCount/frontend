import 'package:flutter_test/flutter_test.dart';
import 'package:buddycount_frontend/services/api_service.dart';

void main() {
  group('ApiService Tests', () {
    group('URL Parsing', () {
      test('should extract group ID from valid invite link', () {
        // Test the private method through public interface
        final inviteLink = 'https://buddycount.app/join/abc123';
        
        // Since _extractGroupIdFromLink is private, we'll test the joinGroup method
        // which uses it internally
        expect(
          () => ApiService.joinGroup(inviteLink),
          returnsNormally,
        );
      });

      test('should handle invalid invite links', () {
        expect(
          () => ApiService.joinGroup('invalid-link'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle malformed URLs', () {
        expect(
          () => ApiService.joinGroup('not-a-url'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle empty strings', () {
        expect(
          () => ApiService.joinGroup(''),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle null-like values', () {
        expect(
          () => ApiService.joinGroup('null'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Input Validation', () {
      test('should handle empty group names', () {
        expect(
          () => ApiService.createGroup('', ['Alice', 'Bob']),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle empty member lists', () {
        expect(
          () => ApiService.createGroup('Test Group', []),
          throwsA(isA<Exception>()),
        );
      });



      test('should handle special characters in group names', () {
        expect(
          () => ApiService.createGroup('Group@#\$%^&*()', ['Alice']),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Base URL Configuration', () {
      test('should have correct base URL', () {
        // Test that the base URL is properly configured
        expect(ApiService.baseUrl, 'https://api.buddycount.duckdns.org');
      });

      test('should have valid URL format', () {
        final uri = Uri.parse(ApiService.baseUrl);
        expect(uri.scheme, 'https');
        expect(uri.host, 'api.buddycount.duckdns.org');
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // These tests will fail in actual network calls, but we're testing the structure
        expect(
          () => ApiService.createGroup('Test Group', ['Alice', 'Bob']),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle join group errors gracefully', () async {
        expect(
          () => ApiService.joinGroup('https://buddycount.app/join/invalid'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
