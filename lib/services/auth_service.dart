/**
 * File: auth_service.dart
 * Description: Auth service, provides methods to interact with the backend
 * Author: Sergey Komarov
 * Date: 2025-09-05
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'device_id_service.dart';

// Class for the Auth Service
class AuthService {
  static const String _baseUrl = 'https://api.buddycount.duckdns.org';
  static const String _tokenBoxName = 'auth_tokens';
  static const String _tokenKey = 'jwt_token';
  static const String _deviceIdKey = 'device_id';
  
  static Box? _tokenBox;
  static String? _cachedToken;
  static String? _cachedDeviceId;
  
  /// Initializes the auth service and opens the token storage box
  static Future<void> initialize() async {
    _tokenBox = await Hive.openBox(_tokenBoxName);
    _loadCachedToken();
  }
  
  /// Loads the cached token from storage
  static void _loadCachedToken() {
    if (_tokenBox != null) {
      _cachedToken = _tokenBox!.get(_tokenKey);
      _cachedDeviceId = _tokenBox!.get(_deviceIdKey);
    }
  }
  
  /// Gets the current JWT token, authenticating if necessary
  static Future<String?> getToken() async {
    // Return cached token if available
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      print('🔐 Using cached token - Length: ${_cachedToken!.length}');
      return _cachedToken;
    }
    
    print('🔐 No cached token - authenticating...');
    // Authenticate to get a new token
    return await authenticate();
  }
  
  /// Authenticates the device and gets a JWT token
  static Future<String?> authenticate() async {
    try {
      // Get device ID
      final deviceId = await DeviceIdService.getDeviceId();
      
      // Make authentication request
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/device'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'deviceId': deviceId,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final token = responseData['access_token'] as String?;

        print('Authentication successful: $token');
        
        if (token != null && token.isNotEmpty) {
          // Cache the token and device ID
          await _cacheToken(token, deviceId);
          print('✅ Authentication successful - Token cached');
          return token;
        } else {
          print('❌ Authentication failed - No token in response');
        }
      } else {
        print('❌ Authentication failed: ${response.statusCode} - ${response.body}');
      }
      
      return null;
    } catch (e) {
      print('Authentication error: $e');
      return null;
    }
  }
  
  /// Caches the JWT token and device ID
  static Future<void> _cacheToken(String token, String deviceId) async {
    if (_tokenBox != null) {
      await _tokenBox!.put(_tokenKey, token);
      await _tokenBox!.put(_deviceIdKey, deviceId);
      _cachedToken = token;
      _cachedDeviceId = deviceId;
      print('💾 Token cached successfully - Length: ${token.length}');
    } else {
      print('❌ Token box not initialized - cannot cache token');
    }
  }
  
  /// Clears the stored authentication token
  static Future<void> clearToken() async {
    if (_tokenBox != null) {
      await _tokenBox!.delete(_tokenKey);
      await _tokenBox!.delete(_deviceIdKey);
      _cachedToken = null;
      _cachedDeviceId = null;
    }
  }
  
  /// Checks if the user is currently authenticated
  static bool isAuthenticated() {
    return _cachedToken != null && _cachedToken!.isNotEmpty;
  }
  
  /// Gets the cached device ID
  static String? getCachedDeviceId() {
    return _cachedDeviceId;
  }
  
  /// Refreshes the authentication token
  static Future<String?> refreshToken() async {
    // Clear current token and re-authenticate
    await clearToken();
    return await authenticate();
  }
  
  /// Closes the token storage box
  static Future<void> dispose() async {
    if (_tokenBox != null) {
      await _tokenBox!.close();
      _tokenBox = null;
    }
  }
}
