import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'web_local_storage.dart' if (dart.library.io) 'noop.dart';
import "package:shimmer/shimmer.dart";
import 'services/wbt_price.dart';
import 'services/soul_service.dart';
import 'utils/reward_calculator.dart';

void main() {
  runApp(const SoulApp());
}


class SoulApp extends StatelessWidget {
  const SoulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soul Info',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurpleAccent,
        ),
      ),
      home: const SoulHomePage(),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
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


  Future<void> fetchSoulData(String soulId) async {
    setState(() => loading = true);
    final client = http.Client();
    try {
      final data = await soulService.fetchSoul(soulId, client);
      final price = await priceService.fetchPrice(client);
      setState(() {
        soulData = data;
        wbtPrice = price;
        final holdAmount = double.tryParse(soulData!['holdAmount'].toString()) ?? 0.0;
        final rewardPercent = double.tryParse(soulData!['rewardPercent'].toString()) ?? 0.0;

        futureRewards = {
          'In 3 months': "${formatTokens(RewardCalculator.calculateFuture(currentAmount: holdAmount, rewardPercent: rewardPercent, months: 3))} WBT",
          'In 6 months': "${formatTokens(RewardCalculator.calculateFuture(currentAmount: holdAmount, rewardPercent: rewardPercent, months: 6))} WBT",
          'In 1 year': "${formatTokens(RewardCalculator.calculateFuture(currentAmount: holdAmount, rewardPercent: rewardPercent, months: 12))} WBT",
        };
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error loading data: $e')),
      );
    } finally {
      client.close();
    }
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
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('saved_soul_id') ?? "1";
      _controller.text = savedId;
      fetchSoulData(savedId);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Cannot open $url')),
      );
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
    return Card(
      color: Colors.grey[900],
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value),
            if (usdValue != null)
              Text(
                "\$${usdValue.toStringAsFixed(2)}",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
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
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Soul ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: loading ? null : () {
                        FocusScope.of(context).unfocus();
                        saveSoulId(_controller.text);
                        fetchSoulData(_controller.text);
                      },
                      child: loading 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Load'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final soulId = _controller.text;
                              openUrl('https://explorer.whitechain.io/soul/$soulId');
                            },
                            child: const Text('Explorer'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              openUrl('https://explorer.whitechain.io/address/0x0000000000000000000000000000000000001001/contract/write#claim');
                            },
                            child: const Text('Claim'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (loading)
                const Expanded(
                  child: Center(
                    child: ShimmerPlaceholderList(),
                  ),
                )
              else if (soulData != null)
                Expanded(
                  child: ListView(
                    children: [
                      buildCard("🕐 Next Reward Date", formatDate(soulData!['nextRewardStartAt'])),
                      buildCard(
                        "⏭️ Next Reward",
                        "${formatTokens(double.tryParse(soulData!['nextRewardAmount'].toString()) ?? 0.0)} WBT"
                      ),
                      buildCard(
                        "💰 Hold Amount",
                        "${formatTokens(double.tryParse(soulData!['holdAmount'].toString()) ?? 0.0)} WBT"
                      ),
                      buildCard(
                        "🎁 Reward Available",
                        "${formatTokens(double.tryParse(soulData!['rewardAvailableAmount'].toString()) ?? 0.0)} WBT"
                      ),
                      buildCard("📊 Reward %", "${formatPercent(soulData!['rewardPercent'])}%"),
                      buildCard(
                        "📤 Claimed Reward",
                        "${formatTokens(double.tryParse(soulData!['rewardClaimedAmount'].toString()) ?? 0.0)} WBT"
                      ),
                      if (wbtPrice != null)
                        buildCard("💵 WBT Price (USDT)", "\$${wbtPrice!.toStringAsFixed(2)}"),
                      if (futureRewards != null) ...futureRewards!.entries.map((entry) =>
                        buildCard("📈 ${entry.key}", entry.value),
                      ),
                    ],
                  ),
                )
              else
                const Expanded(child: Center(child: Text('No data found'))),
            ],
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

class ShimmerPlaceholderList extends StatelessWidget {
  const ShimmerPlaceholderList({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: const ListTile(
            title: SizedBox(height: 16, width: double.infinity, child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey))),
            subtitle: SizedBox(height: 14, width: double.infinity, child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey))),
          ),
        ),
      ),
    );
  }
}