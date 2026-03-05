import 'package:flutter/material.dart';

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
    final holdAmount =
        double.tryParse(soulData['holdAmount'].toString()) ?? 0.0;
    final rewardPercent =
        double.tryParse(soulData['rewardPercent'].toString()) ?? 0.0;
    final nextReward =
        double.tryParse(soulData['nextRewardAmount'].toString()) ?? 0.0;
    final rewardAvailable =
        double.tryParse(
          soulData['rewardAvailableAmount']?.toString() ?? '0.0',
        ) ??
        0.0;
    final rewardClaimed =
        double.tryParse(soulData['rewardClaimedAmount']?.toString() ?? '0.0') ??
        0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 760 ? 2 : 1;
        final tileHeight = constraints.maxWidth >= 760 ? 132.0 : 118.0;

        final mainCards = <Widget>[
          SoulCard(
            title: 'Current Hold',
            badgeLabel: 'LIVE',
            badgeColor: AppColors.success,
            content: _MetricBlock(amount: holdAmount, wbtPrice: wbtPrice),
            trailing: _InfoChip(
              label: '${Formatters.formatPercent(rewardPercent)}%',
              color: AppColors.success,
            ),
          ),
          SoulCard(
            title: 'Next Reward',
            badgeLabel: 'UPCOMING',
            badgeColor: AppColors.info,
            content: _MetricBlock(amount: nextReward, wbtPrice: wbtPrice),
            trailing: _InfoChip(
              label: UrlUtils.formatDuration(timeLeft),
              color: AppColors.info,
            ),
          ),
          SoulCard(
            title: 'Available',
            badgeLabel: rewardAvailable > 0 ? 'READY' : 'EMPTY',
            badgeColor: rewardAvailable > 0
                ? AppColors.secondary
                : AppColors.textMuted,
            content: _MetricBlock(amount: rewardAvailable, wbtPrice: wbtPrice),
          ),
          SoulCard(
            title: 'Claimed',
            badgeLabel: 'TOTAL',
            badgeColor: AppColors.primary,
            content: _MetricBlock(amount: rewardClaimed, wbtPrice: wbtPrice),
          ),
        ];

        return ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mainCards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: tileHeight,
              ),
              itemBuilder: (context, index) => mainCards[index],
            ),
            const SizedBox(height: 10),
            if (futureRewards != null && futureRewards!.isNotEmpty)
              _ForecastSection(
                futureRewards: futureRewards!,
                wbtPrice: wbtPrice,
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                'Next reward date: ${UrlUtils.formatDate(soulData['nextRewardStartAt'])}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ForecastSection extends StatelessWidget {
  final Map<String, String> futureRewards;
  final double? wbtPrice;

  const _ForecastSection({required this.futureRewards, required this.wbtPrice});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      collapsedIconColor: AppColors.textMuted,
      iconColor: AppColors.text,
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      title: const Text(
        'Forecast (optional)',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      ),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: futureRewards.entries.map((entry) {
            final amount =
                double.tryParse(entry.value.replaceAll(' WBT', '')) ?? 0.0;
            final usd = wbtPrice != null ? amount * wbtPrice! : null;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderMuted),
              ),
              child: Text(
                usd == null
                    ? '${entry.key}: ${Formatters.formatTokens(amount)} WBT'
                    : '${entry.key}: ${Formatters.formatTokens(amount)} WBT (\$${usd.toStringAsFixed(2)})',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final double amount;
  final double? wbtPrice;

  const _MetricBlock({required this.amount, required this.wbtPrice});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AnimatedAmountText(amount: amount),
        if (wbtPrice != null)
          Text(
            '\$${(amount * wbtPrice!).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _AnimatedAmountText extends StatefulWidget {
  final double amount;

  const _AnimatedAmountText({required this.amount});

  @override
  State<_AnimatedAmountText> createState() => _AnimatedAmountTextState();
}

class _AnimatedAmountTextState extends State<_AnimatedAmountText> {
  late double _previousAmount;

  @override
  void initState() {
    super.initState();
    _previousAmount = widget.amount;
  }

  @override
  void didUpdateWidget(covariant _AnimatedAmountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _previousAmount = oldWidget.amount;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _previousAmount, end: widget.amount),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          '${Formatters.formatTokens(value)} WBT',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        );
      },
    );
  }
}
