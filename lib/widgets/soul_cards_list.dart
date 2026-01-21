import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/url_utils.dart';
import 'soul_card.dart';

class SoulCardsList extends StatelessWidget {
  final Map<String, dynamic> soulData;
  final Map<String, String>? futureRewards;
  final double? wbtPrice;
  final Duration? timeLeft;

  const SoulCardsList({
    super.key,
    required this.soulData,
    this.futureRewards,
    this.wbtPrice,
    this.timeLeft,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Current Hold
        SoulCard(
          title: '💰 Current Hold',
          content: Builder(
            builder: (context) {
              final holdAmount =
                  double.tryParse(soulData['holdAmount'].toString()) ?? 0.0;
              final holdUsd = wbtPrice != null ? holdAmount * wbtPrice! : null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Formatters.formatTokens(holdAmount)} WBT',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  if (holdUsd != null) const SizedBox(height: 4),
                  if (holdUsd != null)
                    Text(
                      '\$${holdUsd.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.text,
                      ),
                    ),
                ],
              );
            },
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${Formatters.formatPercent(double.tryParse(soulData['rewardPercent'].toString()) ?? 0.0)}%',
              style: const TextStyle(fontWeight: FontWeight.w300),
            ),
          ),
        ),

        // Next Reward
        SoulCard(
          title: '⏭️ Next Reward',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${Formatters.formatTokens(double.tryParse(soulData['nextRewardAmount'].toString()) ?? 0.0)} WBT",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              if (wbtPrice != null) ...[
                const SizedBox(height: 4),
                Text(
                  "\$${((double.tryParse(soulData['nextRewardAmount'].toString()) ?? 0.0) * wbtPrice!).toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const SizedBox(width: 6),
                  Text(
                    UrlUtils.formatDuration(timeLeft),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 6),
                  Text(
                    UrlUtils.formatDate(soulData['nextRewardStartAt']),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Reward Available
        SoulCard(
          title: '🎁 Reward Available',
          content: Builder(
            builder: (context) {
              final amount =
                  double.tryParse(
                    soulData['rewardAvailableAmount']?.toString() ?? '0.0',
                  ) ??
                  0.0;
              final usd = wbtPrice != null ? amount * wbtPrice! : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Formatters.formatTokens(amount)} WBT',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  if (usd != null) const SizedBox(height: 4),
                  if (usd != null)
                    Text(
                      '\$${usd.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              );
            },
          ),
        ),

        // Claimed Reward
        SoulCard(
          title: '📤 Claimed Reward',
          content: Builder(
            builder: (context) {
              final amount =
                  double.tryParse(
                    soulData['rewardClaimedAmount']?.toString() ?? '0.0',
                  ) ??
                  0.0;
              final usd = wbtPrice != null ? amount * wbtPrice! : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Formatters.formatTokens(amount)} WBT',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  if (usd != null) const SizedBox(height: 4),
                  if (usd != null)
                    Text(
                      '\$${usd.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              );
            },
          ),
        ),

        // Future Rewards
        if (futureRewards != null)
          ...futureRewards!.entries.map((entry) {
            final amount =
                double.tryParse(entry.value.replaceAll(' WBT', '')) ?? 0.0;
            final usd = wbtPrice != null ? amount * wbtPrice! : null;

            return SoulCard(
              title: '📈 ${entry.key}',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Formatters.formatTokens(amount)} WBT',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  if (usd != null) const SizedBox(height: 4),
                  if (usd != null)
                    Text(
                      '\$${usd.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}
