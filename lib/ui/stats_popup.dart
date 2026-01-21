import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

  Widget statsRow(BuildContext context, String title, dynamic value, dynamic day, dynamic week, dynamic month) {
    String main = _formatValue(value);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final fontSize = isMobile ? 10.0 : 12.0;
    
    if (isMobile) {
      // Vertical layout for mobile
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: fontSize + 1,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildMobileCell('Value', main, fontSize, isBold: true),
                ),
                Expanded(
                  child: _buildMobileCell('Day', _formatValue(day), fontSize, icon: day),
                ),
                Expanded(
                  child: _buildMobileCell('Week', _formatValue(week), fontSize, icon: week),
                ),
                Expanded(
                  child: _buildMobileCell('Month', _formatValue(month), fontSize, icon: month),
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    // Horizontal layout for desktop
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
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize,
                ),
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
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                ),
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
                      fontSize: fontSize,
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
                      fontSize: fontSize,
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
                      fontSize: fontSize,
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

  Widget _buildMobileCell(String label, String value, double fontSize, {bool isBold = false, dynamic icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize - 1,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                  color: isBold ? AppColors.text : AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (icon != null) _deltaIcon(icon),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final fontSize = isMobile ? 10.0 : 12.0;
    
    return AlertDialog(
      title: const Text('Soul Stats'),
      contentPadding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) ...[
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      "Name",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Value",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Day",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Week",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Month",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const Divider(),
            ],
            statsRow(
              context,
              "Total Souls",
              stats['soulsTotal']?['value'] ?? 0,
              stats['soulsTotal']?['differences']?['day'],
              stats['soulsTotal']?['differences']?['week'],
              stats['soulsTotal']?['differences']?['month'],
            ),
            statsRow(
              context,
              "Holder Souls (10+ WBT)",
              stats['soulsHolder']?['value'] ?? 0,
              stats['soulsHolder']?['differences']?['day'],
              stats['soulsHolder']?['differences']?['week'],
              stats['soulsHolder']?['differences']?['month'],
            ),
            statsRow(
              context,
              "Zombie Souls (<10 WBT)",
              stats['soulsZombie']?['value'] ?? 0,
              stats['soulsZombie']?['differences']?['day'],
              stats['soulsZombie']?['differences']?['week'],
              stats['soulsZombie']?['differences']?['month'],
            ),
            statsRow(
              context,
              "Launchpad Souls (200+ WBT)",
              stats['soulsLaunchpadReady']?['value'] ?? 0,
              stats['soulsLaunchpadReady']?['differences']?['day'],
              stats['soulsLaunchpadReady']?['differences']?['week'],
              stats['soulsLaunchpadReady']?['differences']?['month'],
            ),
            statsRow(
              context,
              "Total Hold Amount, WBT",
              stats['soulsHoldAmount']?['value'] ?? 0.0,
              stats['soulsHoldAmount']?['differences']?['day'],
              stats['soulsHoldAmount']?['differences']?['week'],
              stats['soulsHoldAmount']?['differences']?['month'],
            ),
            statsRow(
              context,
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