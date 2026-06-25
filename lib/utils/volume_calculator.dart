import '../models/index.dart';

class VolumeCalculator {
  static double calculateSessionVolume(WorkoutSession session) {
    double total = 0;
    for (final exerciseLog in session.exerciseLogs) {
      total += calculateExerciseVolume(exerciseLog);
    }
    return total;
  }

  static double calculateExerciseVolume(ExerciseLog exerciseLog) {
    double total = 0;
    for (final set in exerciseLog.sets) {
      total += set.weightKg * set.reps;
    }
    return total;
  }

  static int countTotalSets(WorkoutSession session) {
    int total = 0;
    for (final exerciseLog in session.exerciseLogs) {
      total += exerciseLog.sets.length;
    }
    return total;
  }

  static int countStartedExercises(WorkoutSession session) {
    return session.exerciseLogs.where((e) => e.sets.isNotEmpty).length;
  }

  static bool hasRegisteredSets(WorkoutSession session) {
    return countTotalSets(session) > 0;
  }

  static bool isRecoverableInProgress(WorkoutSession session) {
    if (session.isFinished) return false;

    final hasRegisteredSets = countTotalSets(session) > 0;
    if (hasRegisteredSets) return true;

    final createdRecently = DateTime.now()
            .difference(session.startDate)
            .inHours <
        12;
    return createdRecently;
  }

  static String formatDuration(DateTime from, [DateTime? to]) {
    final end = to ?? DateTime.now();
    final seconds = end.difference(from).inSeconds;

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  static SetLog? findBestSet(List<SetLog> sets) {
    if (sets.isEmpty) return null;
    return sets.reduce((a, b) {
      if (a.weightKg == b.weightKg) {
        return a.reps > b.reps ? a : b;
      }
      return a.weightKg > b.weightKg ? a : b;
    });
  }
}
