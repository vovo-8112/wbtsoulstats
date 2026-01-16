/// Application constants
class AppConstants {
  // API URLs
  static const String baseApiUrl = 'https://whitestat.com/api/v1';
  static const String soulsEndpoint = '$baseApiUrl/souls';
  static const String statisticsEndpoint = '$baseApiUrl/statistics';
  static const String pricesEndpoint = '$baseApiUrl/prices';

  // External URLs
  static const String whiteStatUrl = 'https://whitestat.com/';
  static const String explorerBaseUrl = 'https://explorer.whitechain.io';
  static const String claimContractUrl =
      '$explorerBaseUrl/address/0x0000000000000000000000000000000000001001/contract/write#claim';

  // Storage keys
  static const String savedSoulIdKey = 'saved_soul_id';

  // Default values
  static const String defaultSoulId = '1';
}
