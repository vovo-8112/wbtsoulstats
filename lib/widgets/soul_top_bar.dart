import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'soul_stats_dialog.dart';
import '../theme/app_colors.dart';

class SoulTopBar extends StatefulWidget {
  const SoulTopBar({super.key, this.soulId});

  final String? soulId;

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

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.query_stats_rounded, size: 16),
            label: const Text('Stats'),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => SoulStatsDialog(initialSoulId: widget.soulId),
              );
            },
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderMuted),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.show_chart_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                FutureBuilder<double?>(
                  future: _price,
                  builder: (context, snapshot) {
                    final price = snapshot.data;
                    return Text(
                      price == null
                          ? 'WBT/USDT —'
                          : 'WBT/USDT ${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
