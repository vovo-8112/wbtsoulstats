import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'web_local_storage.dart' if (dart.library.io) 'noop.dart';

void main() {
  runApp(const SoulApp());
}

/// =========================
/// Main App
/// =========================
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

/// =========================
/// Home Page
/// =========================
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

  /// =========================
  /// Date Formatting
  /// =========================
  String formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown date';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (_) {
      return 'Invalid date format';
    }
  }

  /// =========================
  /// Fetch Data
  /// =========================
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
          'In 3 months': "${RewardCalculator.calculateFuture(currentAmount: holdAmount, rewardPercent: rewardPercent, months: 3).toStringAsFixed(2)} WBT",
          'In 6 months': "${RewardCalculator.calculateFuture(currentAmount: holdAmount, rewardPercent: rewardPercent, months: 6).toStringAsFixed(2)} WBT",
          'In 1 year': "${RewardCalculator.calculateFuture(currentAmount: holdAmount, rewardPercent: rewardPercent, months: 12).toStringAsFixed(2)} WBT",
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

  /// =========================
  /// Storage
  /// =========================
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
      final savedId = getItem('saved_soul_id') ?? "21187";
      _controller.text = savedId;
      fetchSoulData(savedId);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('saved_soul_id') ?? "21187";
      _controller.text = savedId;
      fetchSoulData(savedId);
    } catch (_) {
      _controller.text = "21187";
      fetchSoulData("21187");
    }
  }

  /// =========================
  /// Open URL
  /// =========================
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

  /// =========================
  /// Card Builder
  /// =========================
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

  /// =========================
  /// Build UI
  /// =========================
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
                      buildCard("⏭️ Next Reward", "${soulData!['nextRewardAmount']} WBT"),
                      buildCard("💰 Hold Amount", "${soulData!['holdAmount']} WBT"),
                      buildCard("🎁 Reward Available", "${soulData!['rewardAvailableAmount']} WBT"),
                      buildCard("📊 Reward %", "${soulData!['rewardPercent']}%"),
                      buildCard("📤 Claimed Reward", "${soulData!['rewardClaimedAmount']} WBT"),
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

/// =========================
/// Soul Service
/// =========================
class SoulService {
  static const baseUrl = 'https://whitestat.com/api/v1/souls';

  Future<Map<String, dynamic>?> fetchSoul(String soulId, http.Client client) async {
    final url = '$baseUrl?soulId=$soulId';
    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['souls']?.first;
    } else {
      throw Exception('Error loading soul data: ${response.statusCode}');
    }
  }
}

class WBTPrice {
  static const baseUrl = "https://whitestat.com/api/v1/prices";

  Future<double?> fetchPrice(http.Client client) async {
    final response = await client.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['price'] as num).toDouble();
    } else {
      throw Exception('Error loading price: ${response.statusCode}');
    }
  }
}

/// =========================
/// Reward Calculator
/// =========================
class RewardCalculator {
  static double calculateFuture({
    required double currentAmount,
    required double rewardPercent,
    required int months,
  }) {
    double monthlyRate = rewardPercent / 100;
    double future = currentAmount;
    for (int i = 0; i < months; i++) {
      future += future * monthlyRate;
    }
    return future - currentAmount;
  }
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