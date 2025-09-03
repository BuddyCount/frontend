import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';

class ImageService {
  static const String baseUrl = 'https://api.buddycount.duckdns.org';
  
  /// Upload an image file to the server
  static Future<String?> uploadImage(File imageFile) async {
    try {
      print('📸 Uploading image: ${imageFile.path}');
      
      // Get authentication headers
      final token = await AuthService.getToken();
      final headers = {
        'Accept': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
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
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: contentType,
        ),
      );
      
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
  
  /// Pick an image from gallery or camera
  static Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('💥 Exception in pickImage: $e');
      return null;
    }
  }
  
  /// Show image source selection dialog
  static Future<File?> showImageSourceDialog() async {
    // This will be called from the UI with a context
    // For now, just return null - the UI will handle the dialog
    return null;
  }
}
