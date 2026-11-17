import 'package:http/http.dart' as http;

import 'soul_rewards_service.dart';

class SoulService {
  final SoulRewardsService _rewardsService = SoulRewardsService();

  Future<BigInt> fetchLastSoulId(http.Client client) =>
      _rewardsService.fetchLastSoulId(client);

  Future<Map<String, dynamic>?> fetchSoul(String soulId, http.Client client) =>
      _rewardsService.refreshSoul(soulId, client);
}
