import 'package:intl/intl.dart';
import '../utils/constants.dart';
import 'formatters.dart';

/// Utility functions for URL generation
class UrlUtils {
  /// Generates explorer URL for a soul
  static String getSoulExplorerUrl(String soulId) {
    return '${AppConstants.explorerBaseUrl}/soul/$soulId';
  }

  /// Generates Google Calendar URL for a reward event
  static String getCalendarUrl({
    required DateTime startDateTime,
    required double rewardAmount,
  }) {
    final title = Uri.encodeComponent('Next Soul Reward');
    final details = Uri.encodeComponent(
      'Reward of ${Formatters.formatTokens(rewardAmount)} WBT',
    );

    final endDateTime = startDateTime.add(const Duration(minutes: 5));

    String formatGoogleDate(DateTime dt) =>
        '${dt.toIso8601String().replaceAll(RegExp(r'[:-]'), '').split('.').first}Z';

    return 'https://calendar.google.com/calendar/render?action=TEMPLATE'
        '&text=$title'
        '&details=$details'
        '&dates=${formatGoogleDate(startDateTime)}/${formatGoogleDate(endDateTime)}'
        '&location=Whitechain';
  }

  /// Formats date to local timezone string
  static String formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown date';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (_) {
      return 'Invalid date format';
    }
  }

  /// Formats duration to readable string
  static String formatDuration(Duration? d) {
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
}
