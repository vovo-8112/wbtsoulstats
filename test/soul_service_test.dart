import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wbtsoulstats/services/soul_service.dart';
import 'package:wbtsoulstats/utils/constants.dart';

void main() {
  final hold = BigInt.parse('40650884980000000000');
  final available = BigInt.parse('2184121374088890271');
  final percent = BigInt.from(1053578705);
  final updated = DateTime.parse('2026-06-30T09:22:58Z');
  final claimed = DateTime.parse('2026-06-30T09:19:00Z');
  final now = DateTime.parse('2026-10-29T14:00:00Z');
  final next = DateTime.parse('2026-11-27T09:22:58Z');
  final stale = <String, dynamic>{
    'soulId': 21147,
    'holdAmount': 30,
    'rewardAvailableAmount': 1.6273285558592847,
    'rewardClaimedAmount': 5.223200738802239,
    'rewardPercent': 1.316973381,
    'nextRewardAmount': 0.557,
    'nextRewardStartAt': '2026-11-27T09:22:58Z',
  };

  String hex(BigInt value) => '0x${value.toRadixString(16).padLeft(64, '0')}';
  BigInt seconds(DateTime date) =>
      BigInt.from(date.millisecondsSinceEpoch ~/ 1000);

  MockClient client({
    BigInt? holdValue,
    DateTime? claimDate,
    DateTime? blockDate,
    bool failRpc = false,
    bool malformed = false,
    bool missing = false,
    void Function(List<dynamic>)? onRate,
  }) => MockClient((request) async {
    if (request.method == 'GET') {
      expect(request.url.queryParameters, {'soulId': '21147'});
      return http.Response(
        jsonEncode({
          'souls': missing ? [] : [stale],
        }),
        200,
      );
    }
    expect(request.url.toString(), AppConstants.whitechainRpcUrl);
    final body = jsonDecode(request.body);
    if (body is Map) {
      expect(body['method'], 'eth_getBlockByNumber');
      return http.Response(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 0,
          'result': {
            'number': '0x123',
            'timestamp': hex(seconds(blockDate ?? now)),
          },
        }),
        200,
      );
    }
    final calls = body as List<dynamic>;
    for (final call in calls) {
      expect(call['params'][1], '0x123');
    }
    if (failRpc) {
      return http.Response(
        jsonEncode([
          for (final call in calls)
            {
              'id': call['id'],
              'error': {'code': -32000, 'message': 'Unavailable'},
            },
        ]),
        200,
      );
    }
    if (calls.length == 1) {
      onRate?.call(calls);
      return http.Response(
        jsonEncode([
          {'id': 0, 'result': hex(percent)},
        ]),
        200,
      );
    }
    expect(
      calls[0]['params'][0]['data'],
      '0xf05d426f${BigInt.from(21147).toRadixString(16).padLeft(64, '0')}',
    );
    expect(
      calls[2]['params'][0]['to'],
      AppConstants.soulAttributeRegistryAddress,
    );
    final values = [
      available,
      seconds(claimDate ?? claimed),
      (holdValue ?? hold) << 96,
      seconds(updated),
    ];
    // JSON-RPC batch replies can arrive in any order.
    return http.Response(
      jsonEncode([
        for (final call in calls.reversed)
          {
            'id': call['id'],
            'result': malformed ? '0x' : hex(values[call['id'] as int]),
          },
      ]),
      200,
    );
  });

  test(
    'Soul 21147 uses live claimable balance and scheduled next rate',
    () async {
      final result = (await SoulService().fetchSoul(
        '21147',
        client(
          onRate: (calls) {
            expect(
              calls.single['params'][0]['data'],
              '0xd898cd53${hex(BigInt.one).substring(2)}${hex(seconds(next)).substring(2)}',
            );
          },
        ),
      ))!;
      expect(result['holdAmount'], closeTo(40.65088498, 1e-10));
      expect(
        result['rewardAvailableAmount'],
        closeTo(2.1841213740888903, 1e-12),
      );
      expect(result['rewardPercent'], closeTo(1.053578705, 1e-12));
      final expected =
          (hold + available) * percent ~/ BigInt.from(100000000000);
      expect(result['nextRewardAmount'], expected.toDouble() / 1e18);
      expect(result['nextRewardAmount'], closeTo(0.45130050523207743, 1e-12));
      expect(DateTime.parse(result['nextRewardStartAt']), next);
      expect(DateTime.parse(result['updatedAt']), now);
      expect(result['rewardClaimedAmount'], stale['rewardClaimedAmount']);
    },
  );

  test('claim resets the 30-day reward period', () async {
    final result = (await SoulService().fetchSoul(
      '21147',
      client(claimDate: DateTime.parse('2026-10-20T09:00:00Z')),
    ))!;
    expect(
      DateTime.parse(result['nextRewardStartAt']),
      DateTime.parse('2026-11-19T09:00:00Z'),
    );
  });

  test(
    'at a period boundary the next date advances by a full period',
    () async {
      final result = (await SoulService().fetchSoul(
        '21147',
        client(blockDate: next),
      ))!;
      expect(
        DateTime.parse(result['nextRewardStartAt']),
        next.add(const Duration(days: 30)),
      );
    },
  );

  test(
    'zero hold has no upcoming reward and keeps available balance',
    () async {
      final result = (await SoulService().fetchSoul(
        '21147',
        client(holdValue: BigInt.zero),
      ))!;
      expect(result['nextRewardAmount'], 0);
      expect(result['nextRewardStartAt'], isNull);
      expect(result['rewardPercent'], 0);
      expect(result['holdLevel'], 0);
      expect(result['rewardAvailableAmount'], greaterThan(0));
    },
  );

  test(
    'RPC errors do not fall back to incorrect WhiteStat reward values',
    () async {
      await expectLater(
        SoulService().fetchSoul('21147', client(failRpc: true)),
        throwsException,
      );
    },
  );

  test('empty ABI return is rejected instead of displayed as zero', () async {
    await expectLater(
      SoulService().fetchSoul('21147', client(malformed: true)),
      throwsFormatException,
    );
  });

  test('missing Soul is returned as null', () async {
    expect(
      await SoulService().fetchSoul('21147', client(missing: true)),
      isNull,
    );
  });
}
