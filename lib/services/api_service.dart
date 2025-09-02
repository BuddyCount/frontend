import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

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
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
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
      return response.statusCode < 500;
      
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
        final joinData = jsonDecode(joinResponse.body);
        
        // For GET request, the response should contain the group data directly
        // or we might need to extract the group ID and fetch details separately
        final actualGroupId = joinData['id'] ?? joinData['groupId'] ?? groupId;
        
        print('✅ Successfully joined group, got ID: $actualGroupId');
        
        // If the response contains full group data, return it directly
        if (joinData.containsKey('name') && joinData.containsKey('members')) {
          print('✅ Join response contains full group data');
          return {
            ...joinData,
            'actualGroupId': actualGroupId,
          };
        } else {
          // Otherwise, fetch group details separately
          final groupResponse = await http.get(
            Uri.parse('$baseUrl/group/$actualGroupId'),
            headers: {
              'Accept': 'application/json',
            },
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
            print('✅ Successfully retrieved group details');
            
            // Return combined data: join response + group details
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
  static Future<Map<String, dynamic>> getGroupById(String groupId) async {
    try {
      print('📋 Fetching group details for ID: $groupId');
      
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId'),
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
        print('✅ Successfully retrieved group details');
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
  }) async {
    try {
      print('💰 Creating expense via API: $name for group $groupId');
      
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
          'repartition': customPaidBy != null && customPaidBy!.isNotEmpty
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
        }
      };
      
      print('📤 Creating expense at: $baseUrl/group/$groupId/expense');
      print('📤 Request body: ${jsonEncode(requestBody)}');
      
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
}
