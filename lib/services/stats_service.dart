import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

/// Service for fetching statistics data
class StatsService {
  Future<Map<String, dynamic>> fetchStats(http.Client client) async {
    final response = await client.get(Uri.parse(AppConstants.statisticsEndpoint));
    
    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return {};
      }
      
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Map<String, dynamic>.from(data);
      } catch (e) {
        throw Exception('Failed to parse stats data: $e');
      }
    } else {
      throw Exception('Failed to load stats: ${response.statusCode}');
    }
  }
}
