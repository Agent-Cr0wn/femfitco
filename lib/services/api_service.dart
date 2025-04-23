import 'dart:convert';
import 'dart:io'; // For HttpStatus codes
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For debugPrint
import '../common/constants/api_constants.dart';

class ApiService {
  final String _baseUrl = ApiConstants.baseUrl;
  final http.Client _client;

  // Allow injecting http client for testing
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // Helper to build standard headers, including auth token if provided
  Map<String, String> _buildHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Handle HTTP response, decode JSON, check for success structure
  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('API Response (${response.request?.url}): ${response.statusCode}');
     // debugPrint('API Response Body: ${response.body}'); // Uncomment for detailed debugging

    try {
       // Handle non-2xx status codes first
        if (response.statusCode < 200 || response.statusCode >= 300) {
           // Try to decode error message from backend if available
           String errorMessage = 'API Error: ${response.statusCode} ${response.reasonPhrase}';
            try {
                final decoded = jsonDecode(response.body);
                 if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
                   errorMessage = decoded['message'] ?? errorMessage;
                 }
            } catch (_) {
                 // Ignore decoding error if body isn't valid JSON
            }
           return {'success': false, 'message': errorMessage, 'statusCode': response.statusCode};
        }


      // Decode successful response
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        // Ensure basic success structure expected from backend (can be customized)
        if (decoded.containsKey('success') && decoded.containsKey('message')) {
          // Add status code for potential further checks in UI layer
          decoded['statusCode'] = response.statusCode;
          return decoded;
        } else {
          debugPrint("API Response Format Warning: Missing 'success' or 'message'. Body: ${response.body}");
          // Treat as success if 2xx, but provide a generic message if structure is wrong
          return {'success': true, 'message': 'Operation successful (unexpected format)', 'data': decoded, 'statusCode': response.statusCode};
        }
      } else {
        debugPrint("API Response Format Error: Not a JSON object. Body: ${response.body}");
        return {'success': false, 'message': 'Received non-JSON response from server.', 'statusCode': response.statusCode};
      }
    } catch (e) {
      debugPrint("API Response JSON Decode Error: $e. Body: ${response.body}");
      return {'success': false, 'message': 'Failed to decode server response.', 'statusCode': response.statusCode};
    }
  }

  // --- Public API Methods ---

  Future<Map<String, dynamic>> get(String endpoint, {String? token}) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    debugPrint('API GET: $url');
    try {
      final response = await _client.get(
          url,
          headers: _buildHeaders(token: token)
        ).timeout(const Duration(seconds: 15)); // Add timeout
      return _handleResponse(response);
    } on SocketException {
       debugPrint('API GET Error: No Internet connection ($url)');
       return {'success': false, 'message': 'No Internet connection. Please check your network.'};
    } on http.ClientException catch (e) {
       debugPrint('API GET Error: ClientException: $e ($url)');
       return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      debugPrint('API GET Error: Unexpected error: $e ($url)');
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data, {String? token}) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
     debugPrint('API POST: $url');
     // debugPrint('API POST Data: ${jsonEncode(data)}'); // Uncomment for debugging sensitive data carefully

    try {
      final response = await _client.post(
        url,
        headers: _buildHeaders(token: token),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 20)); // Longer timeout for POST
      return _handleResponse(response);
     } on SocketException {
       debugPrint('API POST Error: No Internet connection ($url)');
       return {'success': false, 'message': 'No Internet connection. Please check your network.'};
    } on http.ClientException catch (e) {
       debugPrint('API POST Error: ClientException: $e ($url)');
       return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      debugPrint('API POST Error: Unexpected error: $e ($url)');
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

   // Add PUT, DELETE methods similarly if needed
}


