import 'dart:convert';
import 'package:http/http.dart' as http;

class SoulService {
  static const baseUrl = 'https://whitestat.com/api/v1/souls';

  Future<Map<String, dynamic>?> fetchSoul(String soulId, http.Client client) async {
    final url = '$baseUrl?soulId=$soulId';
    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['souls']?.first;
    } else {
      throw Exception('Error loading soul data: ${response.statusCode}');
    }
  }
}