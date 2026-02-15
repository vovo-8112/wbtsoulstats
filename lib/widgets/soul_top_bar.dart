import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_colors.dart';
import '../services/stats_service.dart';
import '../ui/stats_popup.dart';

class SoulTopBar extends StatelessWidget {
  final double? wbtPrice;
  final bool statsLoading;
  final Map<String, dynamic>? statsData;
  final VoidCallback onOpenInfo;
  final void Function(Map<String, dynamic>) onStatsLoaded;
  final void Function(bool) onStatsLoading;

  const SoulTopBar({
    super.key,
    required this.wbtPrice,
    required this.statsLoading,
    required this.statsData,
    required this.onOpenInfo,
    required this.onStatsLoaded,
    required this.onStatsLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (wbtPrice == null) return const SizedBox.shrink();

    final statsService = StatsService();

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: statsLoading
                ? null
                : () async {
                    onStatsLoading(true);
                    final client = http.Client();
                    try {
                      final data = await statsService.fetchStats(client);
                      onStatsLoaded(data);
                      showDialog(
                        context: context,
                        builder: (_) => StatsDialog(stats: data),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ Error loading stats: $e')),
                      );
                    } finally {
                      onStatsLoading(false);
                      client.close();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textButton,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: statsLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Show Stats'),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderMuted, width: 1.1),
            ),
            child: Text(
              'WBT \$${wbtPrice!.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Data from WhiteStat',
            child: GestureDetector(
              onTap: onOpenInfo,
              child: const Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}