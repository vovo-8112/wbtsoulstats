import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatsDialog extends StatelessWidget {
  final Map<String, dynamic> stats;
  const StatsDialog({super.key, required this.stats});

  Widget _deltaIcon(dynamic value) {
    if (value == null) return const SizedBox.shrink();
    final v = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
    if (v == 0) return const SizedBox.shrink();
    final color = v > 0 ? Colors.green : Colors.red;
    final icon = v > 0 ? Icons.arrow_upward : Icons.arrow_downward;
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Icon(icon, color: color, size: 16),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is double || value is int) {
      return value.toDouble().toStringAsFixed(2);
    }
    final parsed = double.tryParse(value.toString());
    if (parsed != null) {
      return parsed.toStringAsFixed(2);
    }
    return value.toString();
  }

  Widget statsRow(String title, dynamic value, dynamic day, dynamic week, dynamic month) {
    String main = _formatValue(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.left,
                softWrap: true,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                main,
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
                softWrap: true,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    _formatValue(day),
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _deltaIcon(day),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    _formatValue(week),
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _deltaIcon(week),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    _formatValue(month),
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _deltaIcon(month),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Soul Stats'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Expanded(flex: 4, child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text("Value", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                Expanded(flex: 3, child: Text("Day", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                Expanded(flex: 3, child: Text("Week", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                Expanded(flex: 3, child: Text("Month", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
            const Divider(),
            statsRow(
              "Total Souls",
              stats['soulsTotal']?['value'] ?? 0,
              stats['soulsTotal']?['differences']?['day'],
              stats['soulsTotal']?['differences']?['week'],
              stats['soulsTotal']?['differences']?['month'],
            ),
            statsRow(
              "Holder Souls (10+ WBT)",
              stats['soulsHolder']?['value'] ?? 0,
              stats['soulsHolder']?['differences']?['day'],
              stats['soulsHolder']?['differences']?['week'],
              stats['soulsHolder']?['differences']?['month'],
            ),
            statsRow(
              "Zombie Souls (<10 WBT)",
              stats['soulsZombie']?['value'] ?? 0,
              stats['soulsZombie']?['differences']?['day'],
              stats['soulsZombie']?['differences']?['week'],
              stats['soulsZombie']?['differences']?['month'],
            ),
            statsRow(
              "Launchpad Souls (200+ WBT)",
              stats['soulsLaunchpadReady']?['value'] ?? 0,
              stats['soulsLaunchpadReady']?['differences']?['day'],
              stats['soulsLaunchpadReady']?['differences']?['week'],
              stats['soulsLaunchpadReady']?['differences']?['month'],
            ),
            statsRow(
              "Total Hold Amount, WBT",
              stats['soulsHoldAmount']?['value'] ?? 0.0,
              stats['soulsHoldAmount']?['differences']?['day'],
              stats['soulsHoldAmount']?['differences']?['week'],
              stats['soulsHoldAmount']?['differences']?['month'],
            ),
            statsRow(
              "Soul Drop Balance, WBT",
              stats['soulsDropAmount']?['value'] ?? 0.0,
              stats['soulsDropAmount']?['differences']?['day'],
              stats['soulsDropAmount']?['differences']?['week'],
              stats['soulsDropAmount']?['differences']?['month'],
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