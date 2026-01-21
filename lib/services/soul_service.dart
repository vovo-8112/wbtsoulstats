import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

/// Service for fetching soul data
class SoulService {
  Future<Map<String, dynamic>?> fetchSoul(String soulId, http.Client client) async {
    final url = '${AppConstants.soulsEndpoint}?soulId=$soulId';
    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final souls = data['souls'] as List?;
      return souls?.isNotEmpty == true ? souls!.first as Map<String, dynamic> : null;
    } else {
      throw Exception('Error loading soul data: ${response.statusCode}');
    }
  }
}