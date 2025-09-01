import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.buddycount.duckdns.org';
  
  // Test connectivity to the backend
  static Future<bool> testConnectivity() async {
    try {
      print('🔍 Testing connectivity to: $baseUrl');
      final response = await http.get(
        Uri.parse('$baseUrl'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      print('🔍 Connectivity test response: ${response.statusCode}');
      return response.statusCode < 500; // Any response means we can reach the server.
    } catch (e) {
      print('🔍 Connectivity test failed: $e');
      return false;
    }
  }
  
  // Create a new group
  static Future<Map<String, dynamic>> createGroup(String groupName, List<String> memberNames, {String description = '', String currency = 'USD'}) async {
    try {
      print('🚀 Creating group via API: $groupName with ${memberNames.length} members');
      
      // Convert member names to the API format
      final users = memberNames.map((name) => {
        'id': name.toLowerCase().replaceAll(' ', '_'), // Generate simple ID from name
        'name': name.trim(),
      }).toList();
      
      final response = await http.post(
        Uri.parse('$baseUrl/group'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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
      
      // Step 1: Send join request to /join/{id}
      final joinResponse = await http.post(
        Uri.parse('$baseUrl/join/$groupId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'inviteLink': inviteLink,
        }),
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
        
        // Extract the actual group ID or token from the response
        final actualGroupId = joinData['groupId'] ?? joinData['id'] ?? joinData['token'];
        
        if (actualGroupId == null) {
          throw Exception('No group ID or token returned from join request');
        }
        
        print('✅ Successfully joined group, got ID: $actualGroupId');
        
        // Step 2: Get group details via /groups/{id}
        final groupResponse = await http.get(
          Uri.parse('$baseUrl/groups/$actualGroupId'),
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
      
      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId'),
        headers: {
          'Accept': 'application/json',
        },
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
      
      final response = await http.delete(
        Uri.parse('$baseUrl/group/$groupId'),
        headers: {
          'Accept': 'application/json',
        },
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
}
