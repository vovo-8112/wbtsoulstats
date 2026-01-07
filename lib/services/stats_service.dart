import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

// --- StatsService ---
class StatsService {
  static const String statsUrl = 'https://whitestat.com/api/v1/statistics';

  Future<Map<String, dynamic>> fetchStats(http.Client client) async {
    final response = await client.get(Uri.parse(statsUrl));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
        (await Future.value(response.body)).isNotEmpty
            ? Map<String, dynamic>.from(
                await Future.value(
                  // ignore: unnecessary_cast
                  (await Future.value(response.body)) is String
                      ? (await Future.value(response.body)).isNotEmpty
                            ? Map<String, dynamic>.from(
                                await Future.value(
                                  jsonDecode(response.body)
                                      as Map<String, dynamic>,
                                ),
                              )
                            : {}
                      : {},
                ),
              )
            : {},
      );
    } else {
      throw Exception('Failed to load stats');
    }
  }
}
