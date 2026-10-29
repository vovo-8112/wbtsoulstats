/// Application constants
class AppConstants {
  // API URLs
  static const String baseApiUrl = 'https://whitestat.com/api/v1';
  static const String soulsEndpoint = '$baseApiUrl/souls';
  static const String statisticsEndpoint = '$baseApiUrl/statistics';
  static const String pricesEndpoint = '$baseApiUrl/prices';
  static const String whitechainRpcUrl = 'https://rpc.whitechain.io';
  static const String soulDropAddress =
      '0x0000000000000000000000000000000000001001';
  static const String soulAttributeRegistryAddress =
      '0x0000000000000000000000000000000000002002';
  static const String holdAmountAttributeAddress =
      '0xe6246b2c5bc67976ed6e28583e94a2a63ff36c93';

  // External URLs
  static const String whiteStatUrl = 'https://whitestat.com/';
  static const String explorerBaseUrl = 'https://explorer.whitechain.io';
  static const String claimContractUrl =
      '$explorerBaseUrl/address/0x0000000000000000000000000000000000001001/contract/write#claim';

  // Storage keys
  static const String savedSoulIdKey = 'saved_soul_id';
  static const String watchlistSoulIdsKey = 'watchlist_soul_ids';
  static const String tileOrderKey = 'tile_order';

  // Default values
  static const String defaultSoulId = '1';
}
