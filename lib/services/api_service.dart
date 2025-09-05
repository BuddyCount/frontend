/**
 * File: api_service.dart
 * Description: API service, provides methods to interact with the backend
 * Author: Sergey Komarov
 * Date: 2025-09-05
 * 
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

// Class for the API service
class ApiService {
  static const String baseUrl = 'https://api.buddycount.duckdns.org';
  
  /// Maps local string IDs to integer IDs for the backend
  static int _mapStringIdToInt(String stringId, List<String> memberNames) {
    print('🔍 Mapping string ID: "$stringId" to integer');
    print('🔍 Available member names: $memberNames');
    
    // Check if stringId is already an integer
    final intId = int.tryParse(stringId);
    if (intId != null) {
      print('🔍 String ID is already an integer: $intId');
      return intId;
    }
    
    // Otherwise, try to map by name
    final index = memberNames.indexWhere((name) => 
      name.toLowerCase().replaceAll(' ', '_') == stringId);
    
    final result = index >= 0 ? index + 1 : 1;
    print('🔍 Mapped "$stringId" to integer: $result');
    return result;
  }
  
  /// Gets headers with authentication token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthService.getToken();
    print('🔐 Getting auth headers - Token: ${token != null ? 'Present (${token.substring(0, 20)}...)' : 'NULL'}');
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      print('🔐 Authorization header set: Bearer ${token.substring(0, 20)}...');
    } else {
      print('🔐 No token available - request will be unauthenticated');
    }
    
    return headers;
  }

  /// Makes an HTTP request with automatic token refresh on 401 errors
  static Future<http.Response> _makeRequestWithTokenRefresh(
    Future<http.Response> Function() requestFunction,
  ) async {
    // First attempt
    var response = await requestFunction();
    
    // If we get a 401, try to refresh the token and retry once
    if (response.statusCode == 401) {
      print('🔄 Got 401 error, attempting token refresh...');
      final newToken = await AuthService.refreshToken();
      
      if (newToken != null) {
        print('✅ Token refreshed successfully, retrying request...');
        response = await requestFunction();
      } else {
        print('❌ Token refresh failed');
      }
    }
    
    return response;
  }
  
  // Test connectivity to the backend
  static Future<bool> testConnectivity() async {
    try {
      print('🔍 Testing connectivity to: $baseUrl');
      
      // Try multiple endpoints to be more robust
      final endpoints = [
        '$baseUrl', // Root endpoint
        '$baseUrl/health', // Health check endpoint
        '$baseUrl/swagger', // Swagger endpoint
      ];
      
      for (final endpoint in endpoints) {
        try {
          print('🔍 Trying endpoint: $endpoint');
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 3));
          
          print('🔍 Connectivity test response: ${response.statusCode}');
          if (response.statusCode < 500) {
            return true; // Any successful response means we can reach the server
          }
        } catch (e) {
          print('🔍 Endpoint $endpoint failed: $e');
          continue; // Try next endpoint
        }
      }
      
      // If all endpoints failed, try a simple ping approach
      print('🔍 All endpoints failed, trying simple connectivity test...');
      final response = await http.get(
        Uri.parse('$baseUrl'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      print('🔍 Final connectivity test response: ${response.statusCode}');
      return response.statusCode < 500; // Any response means we can reach the server.

    } catch (e) {
      print('🔍 Connectivity test failed: $e');
      // If it's a DNS issue but you can reach the backend, assume connectivity is OK
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('nodename nor servname provided')) {
        print('🔍 DNS lookup failed, but assuming connectivity is OK for API calls');
        return true; // Assume connectivity is OK if it's just a DNS issue
      }
      return false;
    }
  }
  
  // Create a new group
  static Future<Map<String, dynamic>> createGroup(String groupName, List<String> memberNames, {String description = '', String currency = 'USD'}) async {
    try {
      print('🚀 Creating group via API: $groupName with ${memberNames.length} members');
      
      // Convert member names to the API format with integer IDs
      final users = memberNames.asMap().entries.map((entry) => {
        'id': entry.key + 1, // Generate integer ID starting from 1
        'name': entry.value.trim(),
      }).toList();
      
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/group'),
        headers: headers,
        body: jsonEncode({
          'name': groupName,
          'description': description,
          'currency': currency,
          'users': users,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out after 10 seconds');
        },
      );
      
      print('📡 API Response: Status ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Group created successfully: ${responseData['id'] ?? 'No ID returned'}');
        return responseData;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create group: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Exception in createGroup: $e');
      throw Exception('Error creating group: $e');
    }
  }
  
  // Join an existing group
  static Future<Map<String, dynamic>> joinGroup(String inviteLink) async {
    try {
      print('🔗 Attempting to join group via invite link: $inviteLink');
      
      // Extract group ID from invite link
      final groupId = _extractGroupIdFromLink(inviteLink);
      print('📋 Extracted group ID: $groupId');
      
      // Step 1: Send join request to /group/join/{linkToken}
      final headers = await _getAuthHeaders();
      final joinResponse = await http.get(
        Uri.parse('$baseUrl/group/join/$groupId'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Join request timed out after 10 seconds');
        },
      );
      
      print('📡 Join API Response: Status ${joinResponse.statusCode}');
      print('📄 Join Response body: ${joinResponse.body}');
      
      if (joinResponse.statusCode == 200 || joinResponse.statusCode == 201) {
        // Handle empty response body from join endpoint
        Map<String, dynamic> joinData = {};
        if (joinResponse.body.isNotEmpty) {
          try {
            joinData = jsonDecode(joinResponse.body);
          } catch (e) {
            print('⚠️ Failed to parse join response JSON: $e');
            // Continue with empty joinData
          }
        }
        
        // Extract group ID - use the original groupId since join response might be empty
        final actualGroupId = joinData['id'] ?? joinData['groupId'] ?? groupId;
        
        print('✅ Successfully joined group, got ID: $actualGroupId');
        
        // If the response contains full group data, return it directly
        if (joinData.containsKey('name') && (joinData.containsKey('members') || joinData.containsKey('users'))) {
          print('✅ Join response contains full group data');
          return {
            ...joinData,
            'actualGroupId': actualGroupId,
          };
        } else {
          // Otherwise, fetch group details with expenses in one request
          final groupResponse = await http.get(
            Uri.parse('$baseUrl/group/$actualGroupId?withExpenses=true'),
            headers: await _getAuthHeaders(),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Group details request timed out after 10 seconds');
            },
          );
          
          print('📡 Group Details Response: Status ${groupResponse.statusCode}');
          print('📄 Group Details body: ${groupResponse.body}');
          
          if (groupResponse.statusCode == 200) {
            final groupData = jsonDecode(groupResponse.body);
            print('✅ Successfully retrieved group details with expenses');
            
            // Return combined data: join response + group details with expenses
            return {
              ...joinData,
              'groupDetails': groupData,
              'actualGroupId': actualGroupId,
            };
          } else {
            throw Exception('Failed to get group details: ${groupResponse.statusCode} - ${groupResponse.body}');
          }
        }
      } else {
        print('❌ Join API Error: ${joinResponse.statusCode} - ${joinResponse.body}');
        throw Exception('Failed to join group: ${joinResponse.statusCode} - ${joinResponse.body}');
      }
    } catch (e) {
      print('💥 Exception in joinGroup: $e');
      throw Exception('Error joining group: $e');
    }
  }
  
  // Extract group ID from invite link
  static String _extractGroupIdFromLink(String inviteLink) {
    try {
      // Handle different invite link formats:
      // 1. https://buddycount.app/join/abc123
      // 2. https://buddycount.app/join/abc123/
      // 3. abc123 (just the ID)
      
      // If it's just an ID, return it directly
      if (!inviteLink.contains('/') && !inviteLink.contains('http')) {
        return inviteLink.trim();
      }
      
      // Parse as URL
      final uri = Uri.parse(inviteLink);
      final pathSegments = uri.pathSegments;
      
      // Look for 'join' in the path and extract the ID after it
      for (int i = 0; i < pathSegments.length - 1; i++) {
        if (pathSegments[i] == 'join') {
          final groupId = pathSegments[i + 1];
          if (groupId.isNotEmpty) {
            return groupId;
          }
        }
      }
      
      // Fallback: try to extract from the last path segment
      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;
        if (lastSegment.isNotEmpty && lastSegment != 'join') {
          return lastSegment;
        }
      }
      
      throw Exception('Could not extract group ID from invite link: $inviteLink');
    } catch (e) {
      throw Exception('Invalid invite link format: $inviteLink. Error: $e');
    }
  }
  
  // Get group details by ID
  static Future<Map<String, dynamic>> getGroupById(String groupId, {bool withExpenses = false}) async {
    try {
      print('📋 Fetching group details for ID: $groupId (withExpenses: $withExpenses)');
      
      final headers = await _getAuthHeaders();
      final url = withExpenses 
          ? '$baseUrl/group/$groupId?withExpenses=true'
          : '$baseUrl/groups/$groupId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out after 10 seconds');
        },
      );
      
      print('📡 Get Group Response: Status ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final groupData = jsonDecode(response.body);
        print('✅ Successfully retrieved group details${withExpenses ? ' with expenses' : ''}');
        return groupData;
      } else {
        print('❌ Get Group Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get group: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Exception in getGroupById: $e');
      throw Exception('Error getting group: $e');
    }
  }
  
  // Delete a group
  static Future<bool> deleteGroup(String groupId) async {
    try {
      print('🗑️ Deleting group via API: $groupId');
      
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/group/$groupId'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Delete request timed out after 10 seconds');
        },
      );
      
      print('📡 Delete Group Response: Status ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Group deleted successfully via API');
        return true;
      } else {
        print('❌ Delete Group Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to delete group: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Exception in deleteGroup: $e');
      throw Exception('Error deleting group: $e');
    }
  }

  // Delete an expense
  static Future<bool> deleteExpense(String expenseId) async {
    try {
      print('🗑️ Deleting expense via API: $expenseId');
      
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/expense/$expenseId'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Delete request timed out after 10 seconds');
        },
      );
      
      print('📡 Delete Expense Response: Status ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Expense deleted successfully via API');
        return true;
      } else {
        print('❌ Delete Expense Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to delete expense: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Exception in deleteExpense: $e');
      throw Exception('Error deleting expense: $e');
    }
  }

  // Update an existing expense
  static Future<Map<String, dynamic>> updateExpense({
    required String expenseId,
    required String groupId,
    required String name,
    required double amount,
    required String currency,
    required String paidByPersonId,
    required List<String> splitBetweenPersonIds,
    required String category,
    required double exchangeRate,
    required List<String> memberNames, // Add member names for ID mapping
    DateTime? date,
    Map<String, double>? customShares, // New parameter for custom shares
    Map<String, double>? customPaidBy, // New parameter for custom paid by amounts
    List<String>? images, // New parameter for image filenames
  }) async {
    try {
      print('💰 Updating expense via API: $name for group $groupId');
      print('🔍 Images parameter received: $images');
      print('🔍 Images is null: ${images == null}');
      print('🔍 Images is empty: ${images?.isEmpty ?? true}');
      
      // Convert our simple model to the complex API format
      final requestBody = {
        'groupId': groupId,
        'name': name,
        'category': category,
        'currency': currency,
        'exchange_rate': exchangeRate,
        'date': (date ?? DateTime.now()).toIso8601String().split('T')[0], // YYYY-MM-DD format
        'amount': amount,
        'paidBy': {
          'repartitionType': 'AMOUNT',
          'repartition': customPaidBy != null && customPaidBy.isNotEmpty
            ? customPaidBy.entries.map((entry) => {
                'userId': _mapStringIdToInt(entry.key, memberNames),
                'values': {
                  'amount': entry.value
                }
              }).toList()
            : [
                {
                  'userId': _mapStringIdToInt(paidByPersonId, memberNames),
                  'values': {
                    'amount': amount
                  }
                }
              ]
        },
        'paidFor': {
          'repartitionType': 'PORTIONS', // Backend only accepts PORTIONS or AMOUNT, not SHARES
          'repartition': customShares != null 
            ? customShares.entries.map((entry) => {
                'userId': _mapStringIdToInt(entry.key, memberNames),
                'values': {
                  'share': entry.value
                }
              }).toList()
            : splitBetweenPersonIds.map((personId) => {
                'userId': _mapStringIdToInt(personId, memberNames),
                'values': {
                  'share': 1
                }
              }).toList()
        },
        // Add images if provided
        if (images != null && images.isNotEmpty) 'images': images,
      };
      
      print('📤 Updating expense at: $baseUrl/expense/$expenseId');
      print('📤 Request body: ${jsonEncode(requestBody)}');
      print('🔍 Images in request body: ${requestBody['images']}');
      
      // Debug custom shares
      if (customShares != null) {
        print('🔍 Custom shares debug:');
        print('🔍 Number of custom shares: ${customShares.length}');
        customShares.forEach((key, value) {
          print('  - Member ID: $key, Share: $value');
        });
        print('🔍 Total shares: ${customShares.values.fold(0.0, (sum, share) => sum + share)}');
        print('🔍 Split between members: $splitBetweenPersonIds');
        print('🔍 Member names: $memberNames');
      }
      
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/expense/$expenseId'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out after 10 seconds');
        },
      );
      
      print('📡 Update Expense Response: Status ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Expense updated successfully: ${responseData['id'] ?? 'No ID returned'}');
        return responseData;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to update expense: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Exception in updateExpense: $e');
      throw Exception('Error updating expense: $e');
    }
  }
  
  // Create an expense
  static Future<Map<String, dynamic>> createExpense({
    required String groupId,
    required String name,
    required double amount,
    required String currency,
    required String paidByPersonId,
    required List<String> splitBetweenPersonIds,
    required String category,
    required double exchangeRate,
    required List<String> memberNames, // Add member names for ID mapping
    DateTime? date,
    Map<String, double>? customShares, // New parameter for custom shares
    Map<String, double>? customPaidBy, // New parameter for custom paid by amounts
    List<String>? images, // New parameter for image filenames
  }) async {
    try {
      print('💰 Creating expense via API: $name for group $groupId');
      print('🔍 Images parameter received: $images');
      print('🔍 Images is null: ${images == null}');
      print('🔍 Images is empty: ${images?.isEmpty ?? true}');
      
      // Convert our simple model to the complex API format
      final requestBody = {
        'groupId': groupId,
        'name': name,
        'category': category,
        'currency': currency,
        'exchange_rate': exchangeRate,
        'date': (date ?? DateTime.now()).toIso8601String().split('T')[0], // YYYY-MM-DD format
        'amount': amount,
        'paidBy': {
          'repartitionType': 'AMOUNT',
          'repartition': customPaidBy != null && customPaidBy.isNotEmpty
            ? customPaidBy.entries.map((entry) => {
                'userId': _mapStringIdToInt(entry.key, memberNames),
                'values': {
                  'amount': entry.value
                }
              }).toList()
            : [
                {
                  'userId': _mapStringIdToInt(paidByPersonId, memberNames),
                  'values': {
                    'amount': amount
                  }
                }
              ]
        },
        'paidFor': {
          'repartitionType': 'PORTIONS', // Backend only accepts PORTIONS or AMOUNT, not SHARES
          'repartition': customShares != null 
            ? customShares.entries.map((entry) => {
                'userId': _mapStringIdToInt(entry.key, memberNames),
                'values': {
                  'share': entry.value
                }
              }).toList()
            : splitBetweenPersonIds.map((personId) => {
                'userId': _mapStringIdToInt(personId, memberNames),
                'values': {
                  'share': 1
                }
              }).toList()
        },
        // Add images if provided
        if (images != null && images.isNotEmpty) 'images': images,
      };
      
      print('📤 Creating expense at: $baseUrl/group/$groupId/expense');
      print('📤 Request body: ${jsonEncode(requestBody)}');
      print('🔍 Images in request body: ${requestBody['images']}');
      
      // Debug custom shares
      if (customShares != null) {
        print('🔍 Custom shares debug:');
        print('🔍 Number of custom shares: ${customShares.length}');
        customShares.forEach((key, value) {
          print('  - Member ID: $key, Share: $value');
        });
        print('🔍 Total shares: ${customShares.values.fold(0.0, (sum, share) => sum + share)}');
        print('🔍 Split between members: $splitBetweenPersonIds');
        print('🔍 Member names: $memberNames');
      }
      
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/group/$groupId/expense'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out after 10 seconds');
        },
      );
      
      print('📡 Create Expense Response: Status ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Expense created successfully: ${responseData['id'] ?? 'No ID returned'}');
        return responseData;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create expense: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Exception in createExpense: $e');
      throw Exception('Error creating expense: $e');
    }
  }

  // Get expense predictions for a group
  static Future<List<double>> getExpensePredictions({
    required String groupId,
    required DateTime startDate,
    required int predictionLength,
  }) async {
    try {
      print('🔮 Fetching expense predictions for group: $groupId');
      print('📅 Start date: $startDate');
      print('📏 Prediction length: $predictionLength days');
      
      // Debug: Check if there are expenses in the group
      print('🔍 Checking group expenses for prediction context...');
      try {
        final groupResponse = await _makeRequestWithTokenRefresh(() async {
          final headers = await _getAuthHeaders();
          return await http.get(
            Uri.parse('$baseUrl/group/$groupId?withExpenses=true'),
            headers: headers,
          );
        });
        
        if (groupResponse.statusCode == 200) {
          final groupData = jsonDecode(groupResponse.body);
          final expenses = groupData['expenses'] as List? ?? [];
          print('🔍 Group has ${expenses.length} expenses');
          if (expenses.isNotEmpty) {
            print('🔍 First expense: ${expenses.first}');
            print('🔍 Last expense: ${expenses.last}');
          }
        }
      } catch (e) {
        print('❌ Failed to check group expenses: $e');
      }
      
      // Format start date as ISO 8601 string
      final startDateString = startDate.toIso8601String();
      final requestUrl = '$baseUrl/group/$groupId/predict?startDate=$startDateString&predictionLength=$predictionLength';
      
      print('🌐 Full request URL: $requestUrl');
      print('📅 Formatted start date: $startDateString');
      
      final response = await _makeRequestWithTokenRefresh(() async {
        final headers = await _getAuthHeaders();
        print('📤 Request headers: $headers');
        return await http.get(
          Uri.parse(requestUrl),
          headers: headers,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Prediction request timed out after 15 seconds');
          },
        );
      });
      
      print('📡 Predictions Response: Status ${response.statusCode}');
      print('📄 Response headers: ${response.headers}');
      print('📄 Response body length: ${response.body.length}');
      print('📄 Full response body: ${response.body}');
      
      // Try to parse as JSON to see the structure
      try {
        final jsonResponse = jsonDecode(response.body);
        print('📄 Parsed JSON response: $jsonResponse');
        print('📄 JSON response type: ${jsonResponse.runtimeType}');
        if (jsonResponse is List) {
          print('📄 Array length: ${jsonResponse.length}');
        }
      } catch (e) {
        print('❌ Failed to parse response as JSON: $e');
      }
      
      if (response.statusCode == 200) {
        final List<dynamic> predictionsData = jsonDecode(response.body);
        final List<double> predictions = predictionsData.cast<double>();
        print('✅ Successfully fetched ${predictions.length} predictions');
        return predictions;
      } else if (response.statusCode == 400) {
        print('❌ Bad Request - Prediction length may be invalid');
        throw Exception('Invalid prediction parameters: ${response.body}');
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get predictions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Exception in getExpensePredictions: $e');
      throw Exception('Error getting expense predictions: $e');
    }
  }
}
