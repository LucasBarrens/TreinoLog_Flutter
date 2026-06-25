import '../models/index.dart';

class PrCalculator {
  // Epley estimated 1RM. Caps reps influence at sane values so a 30+ rep set
  // doesn't artificially inflate.
  static double estimatedOneRm(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0;
    final cappedReps = reps > 30 ? 30 : reps;
    return weight * (1 + cappedReps / 30);
  }

  static double estimatedOneRmFor(SetLog set) {
    return estimatedOneRm(set.weightKg, set.reps);
  }

  static double bestEstimatedOneRm(Iterable<SetLog> sets) {
    double best = 0;
    for (final s in sets) {
      final e = estimatedOneRmFor(s);
      if (e > best) best = e;
    }
    return best;
  }

  static bool isPr(SetLog set, double historicBestOneRm) {
    if (historicBestOneRm <= 0) {
      // First ever logged set with weight+reps counts as a PR.
      return estimatedOneRmFor(set) > 0;
    }
    return estimatedOneRmFor(set) > historicBestOneRm;
  }
}
