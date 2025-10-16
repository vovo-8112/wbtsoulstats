import 'dart:convert';
import 'package:http/http.dart' as http;

class WBTPrice {
  static const baseUrl = "https://whitestat.com/api/v1/prices";

  Future<double?> fetchPrice(http.Client client) async {
    final response = await client.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['price'] as num).toDouble();
    } else {
      throw Exception('Error loading price: ${response.statusCode}');
    }
  }
}