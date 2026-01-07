import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../services/wbt_price.dart';
import '../services/soul_service.dart';
import '../services/stats_service.dart';
import '../utils/reward_calculator.dart';
import '../widgets/soul_card.dart';
import '../widgets/shimmer_placeholder_list.dart';
import '../ui/stats_popup.dart';
import '../web_local_storage.dart' if (dart.library.io) '../noop.dart';
import '../widgets/soul_top_bar.dart';
import '../widgets/soul_controls.dart';

class SoulHomePage extends StatefulWidget {
  const SoulHomePage({super.key});

  @override
  State<SoulHomePage> createState() => _SoulHomePageState();
}

class _SoulHomePageState extends State<SoulHomePage> {
  final TextEditingController _controller = TextEditingController(text: "1");
  Map<String, dynamic>? soulData;
  Map<String, String>? futureRewards;
  bool loading = false;
  double? wbtPrice;
  final WBTPrice priceService = WBTPrice();
  final SoulService soulService = SoulService();
  final StatsService statsService = StatsService();
  Timer? _countdownTimer;
  Duration? _timeLeft;
  Map<String, dynamic>? statsData;
  bool statsLoading = false;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      final uri = Uri.base;
      final soulIdParam = uri.queryParameters['soulid'];
      if (soulIdParam != null && soulIdParam.isNotEmpty) {
        _controller.text = soulIdParam;
        fetchSoulData(soulIdParam);
        saveSoulId(soulIdParam);
        return;
      }
    }

    loadSavedSoulId();
  }

  String formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown date';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (_) {
      return 'Invalid date format';
    }
  }

  void startCountdown(String? isoDate) {
    _countdownTimer?.cancel();
    if (isoDate == null) return;

    final target = DateTime.tryParse(isoDate)?.toUtc();
    if (target == null) return;

    void tick() {
      final now = DateTime.now().toUtc();
      final diff = target.difference(now);

      if (diff.isNegative) {
        _countdownTimer?.cancel();
        setState(() => _timeLeft = Duration.zero);
      } else {
        setState(() => _timeLeft = diff);
      }
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> fetchSoulData(String soulId) async {
    setState(() => loading = true);
    final client = http.Client();
    try {
      final data = await soulService.fetchSoul(soulId, client);
      final price = await priceService.fetchPrice(client);
      soulData = data;
      wbtPrice = price;
      startCountdown(soulData!['nextRewardStartAt']);
      setState(() {
        final holdAmount =
            double.tryParse(soulData!['holdAmount'].toString()) ?? 0.0;
        final rewardPercent =
            double.tryParse(soulData!['rewardPercent'].toString()) ?? 0.0;
        futureRewards = {
          'In 3 months':
              "${formatTokens(RewardCalculator.calculateFuture(currentAmount: holdAmount, rewardPercent: rewardPercent, months: 3))} WBT",
          'In 6 months':
              "${formatTokens(RewardCalculator.calculateFuture(currentAmount: holdAmount, rewardPercent: rewardPercent, months: 6))} WBT",
          'In 1 year':
              "${formatTokens(RewardCalculator.calculateFuture(currentAmount: holdAmount, rewardPercent: rewardPercent, months: 12))} WBT",
        };
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error loading data: $e')));
    } finally {
      client.close();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> saveSoulId(String soulId) async {
    if (kIsWeb) {
      setItem('saved_soul_id', soulId);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_soul_id', soulId);
    } catch (_) {}
  }

  Future<void> loadSavedSoulId() async {
    if (kIsWeb) {
      final savedId = getItem('saved_soul_id') ?? "1";
      _controller.text = savedId;
      fetchSoulData(savedId);

      // Додай це:
      final newUrl = Uri.base.replace(queryParameters: {'soulid': savedId});
      html.window.history.pushState(null, 'Soul Info', newUrl.toString());
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('saved_soul_id') ?? "1";
      _controller.text = savedId;
      fetchSoulData(savedId);

      if (kIsWeb) {
        final newUrl = Uri.base.replace(queryParameters: {'soulid': savedId});
        html.window.history.pushState(null, 'Soul Info', newUrl.toString());
      }
    } catch (_) {
      _controller.text = "1";
      fetchSoulData("1");
    }
  }

  void openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Cannot open $url')));
    }
  }

  Widget buildCard(String title, String value) {
    double? usdValue;
    if (wbtPrice != null && value.contains('WBT')) {
      final match = RegExp(r'([\d.]+)').firstMatch(value);
      if (match != null) {
        final amount = double.tryParse(match.group(1)!);
        if (amount != null) usdValue = amount * wbtPrice!;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderMuted),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  if (usdValue != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "\$${usdValue.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (usdValue != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "\$${usdValue.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.bgDark,
          elevation: 0,
          title: Container(), // порожній заголовок
          actions: [
            SoulTopBar(
              wbtPrice: wbtPrice,
              statsLoading: statsLoading,
              statsData: statsData,
              onOpenInfo: () => openUrl('https://whitestat.com/'),
              onStatsLoaded: (data) => setState(() => statsData = data),
              onStatsLoading: (v) => setState(() => statsLoading = v),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SoulControls(
                      controller: _controller,
                      loading: loading,
                      onLoadPressed: () {
                        FocusScope.of(context).unfocus();
                        saveSoulId(_controller.text);
                        fetchSoulData(_controller.text);
                        if (kIsWeb) {
                          final newUrl = Uri.base.replace(
                            queryParameters: {'soulid': _controller.text},
                          );
                          html.window.history.pushState(
                            null,
                            'Soul Info',
                            newUrl.toString(),
                          );
                        }
                      },
                      onExplorerPressed: () {
                        final soulId = _controller.text;
                        openUrl('https://explorer.whitechain.io/soul/$soulId');
                      },
                      onClaimPressed: () {
                        openUrl(
                          'https://explorer.whitechain.io/address/0x0000000000000000000000000000000000001001/contract/write#claim',
                        );
                      },
                      onAddCalendarPressed: () {
                        final title = Uri.encodeComponent("Next Soul Reward");
                        final details = Uri.encodeComponent(
                          "Reward of ${formatTokens(double.tryParse(soulData?['nextRewardAmount']?.toString() ?? '0.0') ?? 0.0)} WBT",
                        );

                        final startDateTime =
                            DateTime.tryParse(
                              soulData?['nextRewardStartAt'] ?? '',
                            )?.toUtc() ??
                            DateTime.now().toUtc();
                        final endDateTime = startDateTime.add(
                          const Duration(minutes: 5),
                        );

                        String formatGoogleDate(DateTime dt) =>
                            '${dt
                                .toIso8601String()
                                .replaceAll(RegExp(r'[:-]'), '')
                                .split('.')
                                .first}Z';

                        final url = Uri.parse(
                          'https://calendar.google.com/calendar/render?action=TEMPLATE'
                          '&text=$title'
                          '&details=$details'
                          '&dates=${formatGoogleDate(startDateTime)}/${formatGoogleDate(endDateTime)}'
                          '&location=Whitechain',
                        );

                        html.window.open(url.toString(), '_blank');
                      },
                    ),
                  ),
                  if (loading)
                    const Expanded(
                      child: Center(child: ShimmerPlaceholderList()),
                    )
                  else if (soulData != null)
                    Expanded(
                      child: ListView(
                        children: [
                          SoulCard(
                            title: '💰 Current Hold',
                            content: Builder(
                              builder: (context) {
                                final holdAmount =
                                    double.tryParse(
                                      soulData!['holdAmount'].toString(),
                                    ) ??
                                    0.0;
                                final holdUsd = wbtPrice != null
                                    ? holdAmount * wbtPrice!
                                    : null;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${formatTokens(holdAmount)} WBT',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (holdUsd != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${holdUsd.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bgLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${formatPercent(soulData!['rewardPercent'])}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ),
                          SoulCard(
                            title: '⏭️ Next Reward',
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${formatTokens(double.tryParse(soulData!['nextRewardAmount'].toString()) ?? 0.0)} WBT",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                                if (wbtPrice != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "\$${((double.tryParse(soulData!['nextRewardAmount'].toString()) ?? 0.0) * wbtPrice!).toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.timer,
                                      size: 18,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatDuration(_timeLeft),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatDate(
                                        soulData!['nextRewardStartAt'],
                                      ),
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
                          SoulCard(
                            title: '🎁 Reward Available',
                            content: Builder(
                              builder: (context) {
                                final amount =
                                    double.tryParse(
                                      soulData!['rewardAvailableAmount']
                                          .toString(),
                                    ) ??
                                    0.0;
                                final usd = wbtPrice != null
                                    ? amount * wbtPrice!
                                    : null;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${formatTokens(amount)} WBT",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (usd != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        "\$${usd.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                          SoulCard(
                            title: '📤 Claimed Reward',
                            content: Builder(
                              builder: (context) {
                                final amount =
                                    double.tryParse(
                                      soulData!['rewardClaimedAmount']
                                          .toString(),
                                    ) ??
                                    0.0;
                                final usd = wbtPrice != null
                                    ? amount * wbtPrice!
                                    : null;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${formatTokens(amount)} WBT",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (usd != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        "\$${usd.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                          if (futureRewards != null)
                            ...futureRewards!.entries.map((entry) {
                              final amount =
                                  double.tryParse(
                                    entry.value.replaceAll(' WBT', ''),
                                  ) ??
                                  0.0;
                              final usd = wbtPrice != null
                                  ? amount * wbtPrice!
                                  : null;

                              return SoulCard(
                                title: "📈 ${entry.key}",
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${formatTokens(amount)} WBT",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (usd != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        "\$${usd.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    )
                  else
                    const Expanded(child: Center(child: Text('No data found'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String formatTokens(double amount) {
  return amount.toStringAsFixed(2);
}

String formatPercent(double amount) {
  return amount.toStringAsFixed(2);
}

String formatDuration(Duration? d) {
  if (d == null) return '--:--:--';

  final days = d.inDays;
  final hours = d.inHours % 24;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;

  if (days > 0) {
    return '${days}d '
        '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
