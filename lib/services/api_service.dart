import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.buddycount.duckdns.org';
  
  // Create a new group
  static Future<Map<String, dynamic>> createGroup(String groupName, List<String> memberNames) async {
    try {
      print('🚀 Creating group via API: $groupName with ${memberNames.length} members');
      
      final response = await http.post(
        Uri.parse('$baseUrl/groups'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': groupName,
          'members': memberNames,
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
      // Extract group ID from invite link
      final groupId = _extractGroupIdFromLink(inviteLink);
      
      final response = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/join'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inviteLink': inviteLink,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to join group: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error joining group: $e');
    }
  }
  
  // Extract group ID from invite link
  static String _extractGroupIdFromLink(String inviteLink) {
    // This is a placeholder - adjust based on your actual invite link format
    // Example: https://buddycount.app/join/abc123
    final uri = Uri.parse(inviteLink);
    final pathSegments = uri.pathSegments;
    if (pathSegments.length >= 2 && pathSegments[0] == 'join') {
      return pathSegments[1];
    }
    throw Exception('Invalid invite link format');
  }
}
