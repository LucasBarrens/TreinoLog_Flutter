import 'workout_session.dart';
import 'exercise_log.dart';
import 'set_log.dart';

class ExerciseHistoryEntry {
  final WorkoutSession session;
  final ExerciseLog exerciseLog;

  ExerciseHistoryEntry({
    required this.session,
    required this.exerciseLog,
  });

  List<SetLog> get sets => exerciseLog.sets;

  double get volume => sets.fold<double>(
    0,
    (sum, set) => sum + (set.weightKg * set.reps),
  );
}
