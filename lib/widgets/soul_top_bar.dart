import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/soul_service.dart';

class SoulTopBar extends StatefulWidget {
  const SoulTopBar({super.key});

  @override
  State<SoulTopBar> createState() => _SoulTopBarState();
}

class _SoulTopBarState extends State<SoulTopBar> {
  late final Future<double?> _price = _fetchPrice();

  Future<double?> _fetchPrice() async {
    final uri = kIsWeb
        ? Uri.base.resolve('/api/wbt-price')
        : Uri.https('wbtsoulstats.pages.dev', '/api/wbt-price');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['price'] as num?)?.toDouble();
  }

  Future<BigInt> _fetchLastSoulId() async {
    final client = http.Client();
    try {
      return await SoulService().fetchLastSoulId(client);
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder<double?>(
            future: _price,
            builder: (context, snapshot) {
              final price = snapshot.data;
              return Text(
                price == null
                    ? 'WBT/USDT —'
                    : 'WBT/USDT ${price.toStringAsFixed(3)}',
              );
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.query_stats_rounded, size: 16),
            label: const Text('Stats'),
            onPressed: () {
              final lastSoulId = _fetchLastSoulId();
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Whitechain Stats'),
                  content: FutureBuilder<BigInt>(
                    future: lastSoulId,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Unable to load Whitechain stats.');
                      }
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      return Text(
                        'Latest registered Soul ID: ${snapshot.data}',
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
