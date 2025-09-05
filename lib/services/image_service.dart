/**
 * File: image_service.dart
 * Description: Image service, provides methods to upload and get images
 * Author: Sergey Komarov
 * Date: 2025-09-05
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

// Class for the Image Service
class ImageService {
  static const String baseUrl = 'https://api.buddycount.duckdns.org';
  
  /// Upload an image file to the server
  static Future<String?> uploadImage(XFile imageFile, {String? token}) async {
    try {
      print('📸 Uploading image: ${imageFile.path}');
      
      // Get authentication headers
      final authToken = token ?? await AuthService.getToken();
      final headers = {
        'Accept': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/image/upload'),
      );
      
      // Add headers
      request.headers.addAll(headers);
      
      // Determine content type from file extension
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      MediaType contentType;
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          contentType = MediaType('image', 'jpeg');
          break;
        case 'png':
          contentType = MediaType('image', 'png');
          break;
        case 'gif':
          contentType = MediaType('image', 'gif');
          break;
        case 'webp':
          contentType = MediaType('image', 'webp');
          break;
        default:
          contentType = MediaType('image', 'jpeg'); // Default fallback
      }
      
      print('📸 Uploading file with content type: ${contentType.toString()}');
      
      // Add the image file with proper content type
      if (kIsWeb) {
        // For web, use fromBytes with the file data
        final bytes = await imageFile.readAsBytes();
        // Sanitize filename to remove special characters
        final sanitizedFilename = _sanitizeFilename(imageFile.name, fileExtension);
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            contentType: contentType,
            filename: sanitizedFilename,
          ),
        );
      } else {
        // For mobile/desktop, use fromPath
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
            contentType: contentType,
          ),
        );
      }
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📡 Image Upload Response: Status ${response.statusCode}');
      print('📄 Image Upload Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.body;
        print('📄 Raw response data: $responseData');
        
        // The server returns a JSON object with a filename field
        try {
          final jsonData = jsonDecode(responseData);
          final filename = jsonData['filename'] as String;
          print('✅ Image uploaded successfully: $filename');
          return filename;
        } catch (e) {
          print('❌ Failed to parse response JSON: $e');
          // Fallback: try to use the raw response as filename
          final filename = responseData.trim();
          print('✅ Image uploaded successfully (fallback): $filename');
          return filename;
        }
      } else {
        print('❌ Image upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('💥 Exception in uploadImage: $e');
      return null;
    }
  }
  
  /// Get the URL for an image by filename
  static String getImageUrl(String filename) {
    return '$baseUrl/image/$filename';
  }
  
  /// Sanitizes a filename by removing special characters and spaces
  static String _sanitizeFilename(String originalFilename, String extension) {
    // Remove the extension from the original filename
    final nameWithoutExt = originalFilename.replaceAll(RegExp(r'\.[^.]*$'), '');
    
    // Replace special characters and spaces with underscores
    final sanitized = nameWithoutExt
        .replaceAll(RegExp(r'[^\w\-_.]'), '_') // Replace non-alphanumeric chars with _
        .replaceAll(RegExp(r'_+'), '_') // Replace multiple underscores with single _
        .replaceAll(RegExp(r'^_|_$'), ''); // Remove leading/trailing underscores
    
    // Generate a timestamp-based filename to ensure uniqueness
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final finalFilename = '${timestamp}_${sanitized.isNotEmpty ? sanitized : 'image'}.$extension';
    
    print('📸 Sanitized filename: "$originalFilename" -> "$finalFilename"');
    return finalFilename;
  }
  
  /// Pick an image from gallery or camera
  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      return image;
    } catch (e) {
      print('💥 Exception in pickImage: $e');
      return null;
    }
  }
  
  /// Show image source selection dialog
  static Future<XFile?> showImageSourceDialog() async {
    // This will be called from the UI with a context
    // For now, just return null - the UI will handle the dialog
    return null;
  }
}
