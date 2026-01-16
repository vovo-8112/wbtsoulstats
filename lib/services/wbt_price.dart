import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

/// Service for fetching WBT price
class WBTPrice {
  Future<double?> fetchPrice(http.Client client) async {
    final response = await client.get(Uri.parse(AppConstants.pricesEndpoint));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final price = data['price'];
      return price is num ? price.toDouble() : null;
    } else {
      throw Exception('Error loading price: ${response.statusCode}');
    }
  }
}