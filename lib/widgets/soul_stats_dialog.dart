import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/soul_service.dart';
import '../utils/formatters.dart';

class SoulStatsDialog extends StatefulWidget {
  const SoulStatsDialog({super.key, this.initialSoulId});

  final String? initialSoulId;

  @override
  State<SoulStatsDialog> createState() => _SoulStatsDialogState();
}

class _SoulStatsDialogState extends State<SoulStatsDialog> {
  final _client = http.Client();
  final _service = SoulService();
  late final _latestId = _service.fetchLastSoulId(_client);
  Future<Map<String, dynamic>?>? _soul;

  @override
  void initState() {
    super.initState();
    final id = widget.initialSoulId;
    if (id != null) _soul = _service.fetchSoul(id, _client);
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Whitechain Stats'),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<BigInt>(
              future: _latestId,
              builder: (context, snapshot) => Text(
                snapshot.hasData
                    ? 'Latest registered Soul ID: ${snapshot.data}'
                    : snapshot.hasError
                    ? 'Latest Soul ID unavailable'
                    : 'Loading latest Soul ID…',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.initialSoulId,
              decoration: const InputDecoration(
                labelText: 'Soul ID',
                helperText: 'Enter an ID and press Search',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (value) {
                final id = BigInt.tryParse(value.trim());
                if (id == null || id <= BigInt.zero || id.bitLength > 256) {
                  setState(() => _soul = Future.value(null));
                  return;
                }
                setState(
                  () => _soul = _service.fetchSoul(id.toString(), _client),
                );
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>?>(
              future: _soul,
              builder: (context, snapshot) {
                if (_soul == null) return const SizedBox.shrink();
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return const Text('Unable to load Soul data');
                }
                final soul = snapshot.data;
                if (soul == null) return const Text('Soul not found');
                final hold = Formatters.formatTokens(
                  soul['holdAmount'] as double,
                );
                final reward = Formatters.formatTokens(
                  soul['rewardAvailableAmount'] as double,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Soul #${soul['soulId']}'),
                    Text('Hold amount: $hold WBT'),
                    Text('Hold level: ${soul['holdLevel']}'),
                    Text('Available reward: $reward WBT'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
