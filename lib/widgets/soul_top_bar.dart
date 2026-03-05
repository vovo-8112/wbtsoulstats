import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_colors.dart';
import '../services/stats_service.dart';
import '../ui/stats_popup.dart';

class SoulTopBar extends StatelessWidget {
  final double? wbtPrice;
  final bool statsLoading;
  final VoidCallback onOpenInfo;
  final void Function(Map<String, dynamic>) onStatsLoaded;
  final void Function(bool) onStatsLoading;

  const SoulTopBar({
    super.key,
    required this.wbtPrice,
    required this.statsLoading,
    required this.onOpenInfo,
    required this.onStatsLoaded,
    required this.onStatsLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (wbtPrice == null) return const SizedBox.shrink();

    final statsService = StatsService();

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderMuted),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: statsLoading
                    ? null
                    : () async {
                        onStatsLoading(true);
                        final client = http.Client();
                        try {
                          final data = await statsService.fetchStats(client);
                          if (!context.mounted) return;
                          onStatsLoaded(data);
                          showDialog(
                            context: context,
                            builder: (_) => StatsDialog(stats: data),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Error loading stats: $e'),
                            ),
                          );
                        } finally {
                          onStatsLoading(false);
                          client.close();
                        }
                      },
                icon: statsLoading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.query_stats_rounded, size: 14),
                label: const Text('Stats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textButton,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
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
                    Text(
                      'WBT \$${wbtPrice!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                tooltip: '',
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'open_whitestat') {
                    onOpenInfo();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      'Data is sourced from WhiteStat.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'open_whitestat',
                    child: Text(
                      'Open https://whitestat.com',
                      style: TextStyle(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
