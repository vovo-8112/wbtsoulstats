/// Utility functions for formatting values
class Formatters {
  /// Formats token amount to 2 decimal places
  static String formatTokens(double amount) {
    return amount.toStringAsFixed(2);
  }

  /// Formats percentage to 2 decimal places
  static String formatPercent(double amount) {
    return amount.toStringAsFixed(2);
  }
}
