import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'soul_card.dart';
import 'shimmer_placeholder_list.dart';

class SoulBody extends StatelessWidget {
  final bool loading;
  final Map<String, dynamic>? soulData;
  final Map<String, String>? futureRewards;
  final Duration? timeLeft;
  final double? wbtPrice;

  const SoulBody({
    super.key,
    required this.loading,
    required this.soulData,
    required this.futureRewards,
    required this.timeLeft,
    required this.wbtPrice,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const ShimmerPlaceholderList();
    }

    if (soulData == null) {
      return const Center(
        child: Text(
          'No data',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        // ⬇️ НАСТУПНИМ КРОКОМ СЮДИ ПОВЕРНЕМО КАРТКИ
      ],
    );
  }
}