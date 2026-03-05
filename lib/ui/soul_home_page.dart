import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html if (dart.library.io) 'dart:io';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../services/wbt_price.dart';
import '../services/soul_service.dart';
import '../services/storage_service.dart';
import '../utils/reward_calculator.dart';
import '../utils/formatters.dart';
import '../utils/url_utils.dart';
import '../utils/constants.dart';
import '../widgets/soul_cards_list.dart';
import '../widgets/shimmer_placeholder_list.dart';
import '../widgets/soul_top_bar.dart';
import '../widgets/soul_controls.dart';

class SoulHomePage extends StatefulWidget {
  const SoulHomePage({super.key});

  @override
  State<SoulHomePage> createState() => _SoulHomePageState();
}

class _SoulHomePageState extends State<SoulHomePage> {
  final TextEditingController _controller = TextEditingController(
    text: AppConstants.defaultSoulId,
  );
  final FocusNode _soulIdFocusNode = FocusNode();
  Map<String, dynamic>? soulData;
  Map<String, String>? futureRewards;
  bool loading = false;
  double? wbtPrice;
  final WBTPrice _priceService = WBTPrice();
  final SoulService _soulService = SoulService();
  Timer? _countdownTimer;
  Duration? _timeLeft;
  Map<String, dynamic>? statsData;
  bool statsLoading = false;
  DateTime? _lastUpdatedAt;
  String? _lastError;
  List<String> _watchlist = const [];
  List<String> _tileOrder = List<String>.from(SoulCardsList.defaultTileOrder);

  @override
  void initState() {
    super.initState();
    loadWatchlist();
    loadTileOrder();

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
      final data = await _soulService.fetchSoul(soulId, client);
      final price = await _priceService.fetchPrice(client);
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
              "${Formatters.formatTokens(RewardCalculator.calculateFuture(currentAmount: holdAmount, rewardPercent: rewardPercent, months: 3))} WBT",
          'In 6 months':
              "${Formatters.formatTokens(RewardCalculator.calculateFuture(currentAmount: holdAmount, rewardPercent: rewardPercent, months: 6))} WBT",
          'In 1 year':
              "${Formatters.formatTokens(RewardCalculator.calculateFuture(currentAmount: holdAmount, rewardPercent: rewardPercent, months: 12))} WBT",
        };
        _lastUpdatedAt = DateTime.now();
        _lastError = null;
        loading = false;
      });
    } catch (e) {
      setState(() {
        _lastError = e.toString();
        loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error loading data: $e')));
      }
    } finally {
      client.close();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _soulIdFocusNode.dispose();
    super.dispose();
  }

  Future<void> saveSoulId(String soulId) async {
    try {
      await StorageService.setString(AppConstants.savedSoulIdKey, soulId);
    } catch (_) {
      // Silently handle storage errors
    }
  }

  Future<void> loadSavedSoulId() async {
    try {
      final savedId =
          await StorageService.getString(AppConstants.savedSoulIdKey) ??
          AppConstants.defaultSoulId;
      _controller.text = savedId;
      fetchSoulData(savedId);
      _updateUrl(savedId);
    } catch (_) {
      _controller.text = AppConstants.defaultSoulId;
      fetchSoulData(AppConstants.defaultSoulId);
    }
  }

  Future<void> loadWatchlist() async {
    try {
      final ids =
          await StorageService.getStringList(
            AppConstants.watchlistSoulIdsKey,
          ) ??
          <String>[];
      if (!mounted) return;
      setState(
        () => _watchlist = ids.where((id) => id.trim().isNotEmpty).toList(),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _watchlist = const []);
    }
  }

  Future<void> loadTileOrder() async {
    try {
      final stored =
          await StorageService.getStringList(AppConstants.tileOrderKey) ??
          SoulCardsList.defaultTileOrder;
      final sanitized = <String>[
        ...stored.where(SoulCardsList.defaultTileOrder.contains),
        ...SoulCardsList.defaultTileOrder.where((k) => !stored.contains(k)),
      ];
      if (!mounted) return;
      setState(() => _tileOrder = sanitized);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _tileOrder = List<String>.from(SoulCardsList.defaultTileOrder),
      );
    }
  }

  Future<void> _persistTileOrder() async {
    await StorageService.setStringList(AppConstants.tileOrderKey, _tileOrder);
  }

  Future<void> _persistWatchlist() async {
    await StorageService.setStringList(
      AppConstants.watchlistSoulIdsKey,
      _watchlist,
    );
  }

  Future<void> addCurrentToWatchlist() async {
    final soulId = _controller.text.trim();
    if (soulId.isEmpty) return;
    if (_watchlist.contains(soulId)) return;
    setState(() => _watchlist = [soulId, ..._watchlist]);
    await _persistWatchlist();
  }

  Future<void> removeFromWatchlist(String soulId) async {
    setState(
      () => _watchlist = _watchlist.where((id) => id != soulId).toList(),
    );
    await _persistWatchlist();
  }

  Future<void> openFromWatchlist(String soulId) async {
    _controller.text = soulId;
    await saveSoulId(soulId);
    _updateUrl(soulId);
    await fetchSoulData(soulId);
  }

  Future<void> _triggerLoadSoul() async {
    final soulId = _controller.text.trim();
    if (soulId.isEmpty) return;
    FocusScope.of(context).unfocus();
    await saveSoulId(soulId);
    _updateUrl(soulId);
    await fetchSoulData(soulId);
  }

  Future<void> _openTileOrderDialog() async {
    final working = List<String>.from(_tileOrder);
    final saved = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tile Priority'),
          content: SizedBox(
            width: 420,
            child: ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: working.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final item = working.removeAt(oldIndex);
                working.insert(newIndex, item);
              },
              itemBuilder: (context, index) {
                final key = working[index];
                return ListTile(
                  key: ValueKey(key),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.drag_indicator_rounded),
                  title: Text(_tileTitle(key)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, working),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (saved == null) return;
    setState(() => _tileOrder = saved);
    await _persistTileOrder();
  }

  String _tileTitle(String key) {
    switch (key) {
      case 'current_hold':
        return 'Current Hold';
      case 'next_reward':
        return 'Next Reward';
      case 'available':
        return 'Available';
      case 'claimed':
        return 'Claimed';
      default:
        return key;
    }
  }

  void _updateUrl(String soulId) {
    if (!kIsWeb) return;
    final newUrl = Uri.base.replace(queryParameters: {'soulid': soulId});
    html.window.history.pushState(null, 'Soul Info', newUrl.toString());
  }

  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Cannot open $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final updatedText = _lastUpdatedAt == null
        ? 'No updates yet'
        : 'Updated ${_lastUpdatedAt!.hour.toString().padLeft(2, '0')}:${_lastUpdatedAt!.minute.toString().padLeft(2, '0')}';
    final scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.gradientTop,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: 70,
        titleSpacing: 16,
        title: Align(
          alignment: Alignment.centerRight,
          child: SoulTopBar(
            wbtPrice: wbtPrice,
            statsLoading: statsLoading,
            onOpenInfo: () => openUrl(AppConstants.whiteStatUrl),
            onStatsLoaded: (data) => setState(() => statsData = data),
            onStatsLoading: (v) => setState(() => statsLoading = v),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.gradientTop, AppColors.gradientBottom],
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SoulControls(
                        controller: _controller,
                        focusNode: _soulIdFocusNode,
                        loading: loading,
                        onSubmitted: (_) => _triggerLoadSoul(),
                        onLoadPressed: _triggerLoadSoul,
                        onExplorerPressed: () {
                          final soulId = _controller.text;
                          openUrl(UrlUtils.getSoulExplorerUrl(soulId));
                        },
                        onClaimPressed: () {
                          openUrl(AppConstants.claimContractUrl);
                        },
                        onAddCalendarPressed: () {
                          final rewardAmount =
                              double.tryParse(
                                soulData?['nextRewardAmount']?.toString() ??
                                    '0.0',
                              ) ??
                              0.0;
                          final startDateTime =
                              DateTime.tryParse(
                                soulData?['nextRewardStartAt'] ?? '',
                              )?.toUtc() ??
                              DateTime.now().toUtc();

                          final calendarUrl = UrlUtils.getCalendarUrl(
                            startDateTime: startDateTime,
                            rewardAmount: rewardAmount,
                          );

                          if (kIsWeb) {
                            html.window.open(calendarUrl, '_blank');
                          } else {
                            openUrl(calendarUrl);
                          }
                        },
                        onAddToWatchlistPressed: () {
                          addCurrentToWatchlist();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            updatedText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Reorder tiles',
                            onPressed: _openTileOrderDialog,
                            icon: const Icon(
                              Icons.reorder_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (_lastError != null)
                            const Text(
                              'Using previous available data',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_watchlist.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 10,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _watchlist.map((id) {
                                final isSelected =
                                    id == _controller.text.trim();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InputChip(
                                    selected: isSelected,
                                    selectedColor: AppColors.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                    backgroundColor: AppColors.bg,
                                    side: const BorderSide(
                                      color: AppColors.borderMuted,
                                    ),
                                    label: Text(
                                      'Soul #$id',
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.text
                                            : AppColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: () => openFromWatchlist(id),
                                    onDeleted: () => removeFromWatchlist(id),
                                    deleteIcon: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: isSelected
                                          ? AppColors.text
                                          : AppColors.textMuted,
                                    ),
                                    deleteButtonTooltipMessage: 'Remove',
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (loading)
                      const Expanded(
                        child: Center(child: ShimmerPlaceholderList()),
                      )
                    else if (soulData != null)
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.bg,
                          onRefresh: () async {
                            await fetchSoulData(_controller.text);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SoulCardsList(
                              soulData: soulData!,
                              futureRewards: futureRewards,
                              wbtPrice: wbtPrice,
                              timeLeft: _timeLeft,
                              tileOrder: _tileOrder,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 72),
                            _EmptyStateCard(),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): _LoadSoulIntent(),
        SingleActivator(LogicalKeyboardKey.slash): _FocusSoulInputIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _LoadSoulIntent: CallbackAction<_LoadSoulIntent>(
            onInvoke: (_) {
              _triggerLoadSoul();
              return null;
            },
          ),
          _FocusSoulInputIntent: CallbackAction<_FocusSoulInputIntent>(
            onInvoke: (_) {
              if (!_soulIdFocusNode.hasFocus) {
                _soulIdFocusNode.requestFocus();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: scaffold,
          ),
        ),
      ),
    );
  }
}

class _LoadSoulIntent extends Intent {
  const _LoadSoulIntent();
}

class _FocusSoulInputIntent extends Intent {
  const _FocusSoulInputIntent();
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderMuted),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 36,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 12),
            Text(
              'No Soul data loaded',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Enter Soul ID and press "Load Soul Data".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
