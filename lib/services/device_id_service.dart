import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';

class DeviceIdService {
  
  /// Gets a unique device identifier that is hashed for privacy and consistency
  static Future<String> getDeviceId() async {
    try {
      String rawDeviceId;
      
      if (kIsWeb) {
        rawDeviceId = await _getWebDeviceId();
      } else {
        rawDeviceId = await _getMobileDeviceId();
      }
      
      // Hash the device ID for privacy and consistency
      return _hashDeviceId(rawDeviceId);
    } catch (e) {
      // Fallback to a random ID if device identification fails
      return _generateFallbackId();
    }
  }
  
  /// Gets device ID for web platforms
  static Future<String> _getWebDeviceId() async {
    // For web, we'll use a simpler approach without dart:html
    // Generate a unique ID based on timestamp and random component
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _generateRandomComponent();
    final combined = 'web_${timestamp}_$random';
    
    return combined;
  }
  
  /// Gets device ID for mobile platforms
  static Future<String> _getMobileDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    } else {
      return 'unknown_mobile';
    }
  }
  

  
  /// Generates a random component for additional entropy
  static String _generateRandomComponent() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
  
  /// Hashes the device ID for privacy and consistency
  static String _hashDeviceId(String deviceId) {
    final bytes = utf8.encode(deviceId);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Generates a fallback ID if device identification fails
  static String _generateFallbackId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    final bytes = utf8.encode('fallback_$random');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Clears the stored device ID (useful for testing or reset)
  static Future<void> clearDeviceId() async {
    // For web, we can't clear localStorage without dart:html
    // For mobile, we can't clear the system device ID, but we could clear any cached values
    // This is a placeholder for future implementation
  }
}
