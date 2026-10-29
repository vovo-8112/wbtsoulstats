import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';

/// Reads live reward values from SoulDrop, including scheduled rate changes.
class SoulRewardsService {
  static const _periodSeconds = 30 * 24 * 60 * 60;
  static final _weiPerToken = BigInt.from(10).pow(18);
  static final _percentDenominator = BigInt.from(100000000000);

  Future<Map<String, dynamic>> refreshSoul(
    Map<String, dynamic> soul,
    http.Client client,
  ) async {
    final soulId = BigInt.parse(soul['soulId'].toString());
    if (soulId <= BigInt.zero || soulId.bitLength > 256) {
      throw const FormatException('Invalid Soul ID');
    }
    final blockResponse = await _post(client, {
      'jsonrpc': '2.0',
      'id': 0,
      'method': 'eth_getBlockByNumber',
      'params': ['latest', false],
    });
    final block =
        _result(blockResponse as Map<String, dynamic>) as Map<String, dynamic>;
    final blockNumber = block['number'] as String;
    final now = _uint(block['timestamp'] as String).toInt();
    final idWord = _word(soulId);
    final attributeWord = AppConstants.holdAmountAttributeAddress
        .substring(2)
        .padLeft(64, '0');

    // Pin all reads to one block so period boundaries cannot mix snapshots.
    final values = await _calls(client, blockNumber, [
      (
        AppConstants.soulDropAddress,
        'f05d426f$idWord',
      ), // getSoulReward(uint256)
      (
        AppConstants.soulDropAddress,
        '69485f09$idWord',
      ), // claimedAtBySoul(uint256)
      (
        AppConstants.soulAttributeRegistryAddress,
        '9d867d37$idWord$attributeWord', // soulAttributeValue(uint256,address)
      ),
      (
        AppConstants.soulAttributeRegistryAddress,
        'f58fa64b$idWord$attributeWord', // soulAttributeUpdatedAt(uint256,address)
      ),
    ]);
    final available = values[0];
    final claimedAt = values[1].toInt();
    // Solidity bytes20 is left-aligned in its 32-byte ABI return word.
    final hold = values[2] >> 96;
    final holdUpdatedAt = values[3].toInt();
    final intervalStart = holdUpdatedAt > claimedAt ? holdUpdatedAt : claimedAt;
    final level = _holdLevel(hold);
    BigInt percent = BigInt.zero;
    BigInt nextReward = BigInt.zero;
    int? nextRewardAt;

    if (hold > BigInt.zero && holdUpdatedAt > 0) {
      if (intervalStart > now) {
        throw const FormatException('Soul reward period starts in the future');
      }
      nextRewardAt =
          intervalStart +
          ((now - intervalStart) ~/ _periodSeconds + 1) * _periodSeconds;
      final rates = await _calls(client, blockNumber, [
        (
          AppConstants.soulDropAddress,
          // percentByHoldLevelAt(uint8,uint256) includes scheduled changes.
          'd898cd53${_word(BigInt.from(level))}'
              '${_word(BigInt.from(nextRewardAt))}',
        ),
      ]);
      percent = rates.single;
      nextReward = (hold + available) * percent ~/ _percentDenominator;
    }

    return {
      ...soul,
      'holdAmount': _tokens(hold),
      'holdLevel': level,
      'holdAmountUpdatedAt': _date(holdUpdatedAt),
      'rewardAvailableAmount': _tokens(available),
      // API percentages are expressed in percent, e.g. 1.316973381.
      'rewardPercent': percent.toDouble() / 1000000000,
      'nextRewardAmount': _tokens(nextReward),
      'nextRewardStartAt': nextRewardAt == null ? null : _date(nextRewardAt),
      'updatedAt': _date(now),
    };
  }

  Future<List<BigInt>> _calls(
    http.Client client,
    String block,
    List<(String, String)> calls,
  ) async {
    final response = await _post(client, [
      for (var i = 0; i < calls.length; i++)
        {
          'jsonrpc': '2.0',
          'id': i,
          'method': 'eth_call',
          'params': [
            {'to': calls[i].$1, 'data': '0x${calls[i].$2}'},
            block,
          ],
        },
    ]);
    if (response is! List || response.length != calls.length) {
      throw const FormatException('Incomplete Whitechain RPC response');
    }
    final byId = <int, BigInt>{};
    for (final item in response) {
      final entry = item as Map<String, dynamic>;
      final id = entry['id'] as int;
      final value = _result(entry) as String;
      if (!RegExp(r'^0x[0-9a-fA-F]{64}$').hasMatch(value) ||
          id < 0 ||
          id >= calls.length ||
          byId.containsKey(id)) {
        throw const FormatException('Invalid Whitechain contract response');
      }
      byId[id] = _uint(value);
    }
    return [for (var i = 0; i < calls.length; i++) byId[i]!];
  }

  Future<dynamic> _post(http.Client client, Object body) async {
    final response = await client
        .post(
          Uri.parse(AppConstants.whitechainRpcUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Whitechain RPC unavailable: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  dynamic _result(Map<String, dynamic> response) {
    if (response['error'] != null || response['result'] == null) {
      throw Exception('Could not read live Whitechain rewards');
    }
    return response['result'];
  }

  static BigInt _uint(String value) =>
      BigInt.parse(value.substring(2), radix: 16);
  static String _word(BigInt value) => value.toRadixString(16).padLeft(64, '0');
  static double _tokens(BigInt value) =>
      value.toDouble() / _weiPerToken.toDouble();
  static String _date(int seconds) => DateTime.fromMillisecondsSinceEpoch(
    seconds * 1000,
    isUtc: true,
  ).toIso8601String();

  static int _holdLevel(BigInt hold) {
    const thresholds = [
      10,
      200,
      1500,
      4000,
      10000,
      16000,
      30000,
      60000,
      100000,
      160000,
      2000000,
      6000000,
    ];
    return thresholds
        .where((amount) => hold >= BigInt.from(amount) * _weiPerToken)
        .length;
  }
}
