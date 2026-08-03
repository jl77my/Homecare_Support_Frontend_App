import 'dart:convert';
import 'package:http/http.dart' as http;

class CaregiverService {
  // Use http://10.0.2.2:3000 for Android Emulator connecting to local host
  final String baseUrl = "http://10.0.2.2:3000/api/caregiver";

  Future<Map<String, dynamic>> recordHealth(
    String token, 
    String patientId, 
    String hr, 
    String bp, 
    String sugar, 
    String notes
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/health'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'patientId': patientId,
        'heartRate': hr,
        'bloodPressure': bp,
        'bloodSugar': sugar,
        'notes': notes,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return {'error': 'Failed to save health data'};
  }
}