import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'soul_rewards_service.dart';

/// Service for fetching soul data
class SoulService {
  final SoulRewardsService _rewardsService = SoulRewardsService();

  Future<Map<String, dynamic>?> fetchSoul(
    String soulId,
    http.Client client,
  ) async {
    // Live rewards only need the ID, not the WhiteStat response.
    final results = await Future.wait<Map<String, dynamic>?>([
      _fetchMetadata(soulId, client),
      _rewardsService.refreshSoul({'soulId': soulId}, client),
    ], eagerError: true);
    final metadata = results[0];
    if (metadata == null) return null;
    // Never allow stale WhiteStat fields to overwrite live chain values.
    return {...metadata, ...results[1]!};
  }

  Future<Map<String, dynamic>?> _fetchMetadata(
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
      return soul;
    } else {
      throw Exception('Error loading soul data: ${response.statusCode}');
    }
  }
}
