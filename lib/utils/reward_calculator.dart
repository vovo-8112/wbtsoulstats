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