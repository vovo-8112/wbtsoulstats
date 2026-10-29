import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'soul_rewards_service.dart';

/// Service for fetching soul data
class SoulService {
  Future<Map<String, dynamic>?> fetchSoul(
    String soulId,
    http.Client client,
  ) async {
    final uri = Uri.parse(
      AppConstants.soulsEndpoint,
    ).replace(queryParameters: {'soulId': soulId});
    final response = await client.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final souls = data['souls'] as List?;
      if (souls == null || souls.isEmpty) return null;
      final soul = souls.first as Map<String, dynamic>;
      if (soul['soulId'].toString() != soulId) {
        throw const FormatException('Soul API returned a different Soul');
      }
      return SoulRewardsService().refreshSoul(soul, client);
    } else {
      throw Exception('Error loading soul data: ${response.statusCode}');
    }
  }
}
