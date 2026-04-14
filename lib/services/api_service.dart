import 'dart:convert'; // ✅ CORRECTED: Uses colon (:) for Dart SDK libraries
import 'package:flutter/material.dart'; // ✅ CORRECTED: Uses colon (:) for Flutter package
import 'package:http/http.dart' as http;

class ApiService {
  // IMPORTANT: This must be your computer's local IP address
  static const String _baseUrl = "http://192.168.1.6:5000/api";

  // Standard headers for sending JSON data
  static const Map<String, String> _headers = {'Content-Type': 'application/json'};

  // Helper function to handle potential errors and decode responses
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } else {
      // Error from server
      String errorMsg = 'An error occurred';
      try {
        errorMsg = json.decode(response.body)['msg'] ?? 'Server returned status ${response.statusCode}';
      } catch (_) {
        errorMsg = 'Server returned status ${response.statusCode}';
      }
      return {'statusCode': response.statusCode, 'body': {'reply': errorMsg, 'msg': errorMsg}};
    }
  }

  // Helper function to handle network/connection exceptions
  Map<String, dynamic> _handleError(dynamic e) {
    print("API Service Error: $e");
    return {'statusCode': 500, 'body': {'reply': 'Could not connect to the server', 'msg': 'Could not connect to the server'}};
  }

  // --- USER AUTHENTICATION ---
  Future<Map<String, dynamic>> registerUser(String name, String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({'email': email, 'password': password}),
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    final url = Uri.parse('$_baseUrl/auth/google');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({'idToken': idToken}),
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // --- USER DATA ---
  Future<Map<String, dynamic>> getDashboardData(String userId) async {
    final url = Uri.parse('$_baseUrl/users/$userId/dashboard');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
         return json.decode(response.body);
      } else {
         throw Exception('Failed to load dashboard data (Status: ${response.statusCode})');
      }
    } catch (e) {
       throw Exception('Failed to connect: $e');
    }
  }

  // --- PET MANAGEMENT ---
  Future<Map<String, dynamic>> addPet({
    required String name,
    required String breed,
    required int age,
    required String ownerId,
  }) async {
    final url = Uri.parse('$_baseUrl/pets/add');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({'name': name, 'breed': breed, 'age': age, 'ownerId': ownerId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPetDetails(String petId) async {
    final url = Uri.parse('$_baseUrl/pets/$petId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load pet details (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  Future<Map<String, dynamic>> updatePet({
    required String petId,
    required String name,
    required String breed,
    required int age,
  }) async {
    final url = Uri.parse('$_baseUrl/pets/$petId');
    try {
      final response = await http.put(
        url,
        headers: _headers,
        body: json.encode({
          'name': name,
          'breed': breed,
          'age': age,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateMedicalRecords({
    required String petId,
    required List<dynamic> vaccinations,
    required List<dynamic> allergies,
    required String medicalNotes,
  }) async {
    final url = Uri.parse('$_baseUrl/pets/$petId/medical');
    try {
      final response = await http.put(
        url,
        headers: _headers,
        body: json.encode({
          'vaccinations': vaccinations,
          'allergies': allergies,
          'medicalNotes': medicalNotes,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }
  
  // --- VET & APPOINTMENT FUNCTIONS ---
  Future<List<dynamic>> getVerifiedVets() async {
    final url = Uri.parse('$_baseUrl/vets/verified');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error fetching vets: Status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception fetching vets: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> bookAppointment({
    required String reason,
    required String ownerId,
    required String vetId,
    required DateTime selectedDate
  }) async {
    final url = Uri.parse('$_baseUrl/appointments/book');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({
          'selectedDate': selectedDate.toIso8601String(),
          'reason': reason,
          'ownerId': ownerId,
          'vetId': vetId,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> updateAppointmentStatus(String appointmentId, String status) async {
    final url = Uri.parse('$_baseUrl/appointments/$appointmentId/status');
    try {
      final response = await http.put(
        url,
        headers: _headers,
        body: json.encode({'status': status}),
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    final url = Uri.parse('$_baseUrl/appointments/$appointmentId');
    try {
      final response = await http.delete(url, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // --- VET PORTAL FUNCTIONS ---
  Future<Map<String, dynamic>> loginVet(String email, String password) async {
    final url = Uri.parse('$_baseUrl/vets/login');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({'email': email, 'password': password}),
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getVetDashboardData(String vetId) async {
    final url = Uri.parse('$_baseUrl/vets/$vetId/dashboard');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load vet dashboard data (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }
  
  // --- CHATBOT FUNCTION ---
  Future<Map<String, dynamic>> askChatbot(String message, {String? petId}) async {
    final url = Uri.parse('$_baseUrl/chatbot/ask');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({
          'message': message,
          'petId': petId,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // --- HEALTH FUNCTIONS ---
  Future<Map<String, dynamic>?> getLatestHealthRecord(String petId) async {
    final url = Uri.parse('$_baseUrl/health/pet/$petId/latest');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') {
          return null;
        }
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load health data');
      }
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  Future<List<dynamic>> getHealthHistory(String petId) async {
    final url = Uri.parse('$_baseUrl/health/pet/$petId/history');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load health history');
      }
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  Future<void> generateMockHealthData(String petId) async {
    final url = Uri.parse('$_baseUrl/health/pet/$petId/generate-mock');
    try {
      await http.get(url).timeout(const Duration(seconds: 5));
    } catch (e) {
      print("Failed to generate mock data: $e");
    }
  }

  // --- ANALYSIS FUNCTION ---
  Future<Map<String, dynamic>> getHealthAnalysis(String petId) async {
    final url = Uri.parse('$_baseUrl/analysis/pet/$petId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 'Error', 'message': 'Could not load health analysis.'};
      }
    } catch (e) {
      print("Failed to get health analysis: $e");
      return {'status': 'Error', 'message': 'Could not connect to analysis service.'};
    }
  }

  // --- VISION FUNCTION ---
  Future<Map<String, dynamic>> analyzeSymptom({
    required String prompt,
    required String imageBase64,
    required String imageMimeType,
  }) async {
    final url = Uri.parse('$_baseUrl/vision/analyze');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({
          'prompt': prompt,
          'imageBase64': imageBase64,
          'imageMimeType': imageMimeType,
        }),
      ).timeout(const Duration(seconds: 30));
      
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // --- RECOMMENDATION FUNCTION ---
  Future<Map<String, dynamic>> getRecommendation(String userId) async {
    final url = Uri.parse('$_baseUrl/analysis/user/$userId/recommendations');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'recommendation': 'Could not load AI recommendation.'};
      }
    } catch (e) {
      print("Failed to get recommendation: $e");
      return {'recommendation': 'Could not connect to analysis service.'};
    }
  }

  // --- BREED FUNCTION ---
  Future<List<String>> getBreeds(String animalType) async {
    final url = Uri.parse('$_baseUrl/breeds?type=$animalType');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // The server sends a list of strings, so we cast it
        return List<String>.from(json.decode(response.body));
      } else {
        return [];
      }
    } catch (e) {
      print("Failed to get breeds: $e");
      return [];
    }
  }

  // --- LOCATION FUNCTIONS ---
  Future<Map<String, dynamic>> issueFindPetCommand(String petId) async {
    final url = Uri.parse('$_baseUrl/commands/pet/$petId/find');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({}), // No body needed, just the URL
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>?> getLatestLocation(String petId) async {
    final url = Uri.parse('$_baseUrl/location/pet/$petId/latest');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') {
          return null; // No location found
        }
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load location data');
      }
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }
}