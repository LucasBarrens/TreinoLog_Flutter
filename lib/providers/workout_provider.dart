import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/database_service.dart';
import '../utils/index.dart';

final workoutActionsProvider = Provider((ref) => const WorkoutActions());

final workoutTemplatesProvider =
    FutureProvider<List<WorkoutTemplate>>((ref) async {
  return DatabaseService.getWorkoutTemplates();
});

final workoutSessionsWithLogsProvider =
    FutureProvider<List<WorkoutSession>>((ref) async {
  return _loadWorkoutSessionsWithLogs();
});

final exerciseTemplatesProvider =
    FutureProvider.family<List<ExerciseTemplate>, String>((ref, workoutName) async {
  return DatabaseService.getExerciseTemplates(workoutName);
});

final exerciseLogsProvider =
    FutureProvider.family<List<ExerciseLog>, String>((ref, sessionId) async {
  return _loadExerciseLogsWithSets(sessionId);
});

final setLogsProvider =
    FutureProvider.family<List<SetLog>, String>((ref, exerciseLogId) async {
  return DatabaseService.getSetLogsByExercise(exerciseLogId);
});

final exerciseHistoryProvider =
    FutureProvider.family<List<ExerciseHistoryEntry>, String>((ref, exerciseKey) async {
  final sessions = await _loadWorkoutSessionsWithLogs();
  final finishedSessions = sessions
      .where((s) => s.isFinished && VolumeCalculator.hasRegisteredSets(s))
      .toList();

  final entries = <ExerciseHistoryEntry>[];

  for (final session in finishedSessions) {
    for (final exercise in session.exerciseLogs) {
      final effectiveKey = exercise.exerciseKey.isEmpty
          ? ExerciseKeyUtil.make(exercise.exerciseName)
          : exercise.exerciseKey;

      if (effectiveKey == exerciseKey && exercise.sets.isNotEmpty) {
        entries.add(
          ExerciseHistoryEntry(
            session: session,
            exerciseLog: exercise,
          ),
        );
      }
    }
  }

  entries.sort((a, b) => b.session.date.compareTo(a.session.date));
  return entries;
});

// Best historic estimated 1RM for an exercise key. Used to flag PRs in the
// current workout (a set beats it ⇒ PR badge). Excludes the in-progress
// session by default so a heavy set being logged right now doesn't shadow
// itself.
class HistoricBestArgs {
  final String exerciseKey;
  final String? excludeSessionId;
  const HistoricBestArgs(this.exerciseKey, {this.excludeSessionId});

  @override
  bool operator ==(Object other) =>
      other is HistoricBestArgs &&
      other.exerciseKey == exerciseKey &&
      other.excludeSessionId == excludeSessionId;

  @override
  int get hashCode => Object.hash(exerciseKey, excludeSessionId);
}

final historicBestOneRmProvider =
    FutureProvider.family<double, HistoricBestArgs>((ref, args) async {
  final sessions = await _loadWorkoutSessionsWithLogs();
  double best = 0;
  for (final session in sessions) {
    if (!session.isFinished) continue;
    if (args.excludeSessionId != null && session.id == args.excludeSessionId) {
      continue;
    }
    for (final exercise in session.exerciseLogs) {
      final effectiveKey = exercise.exerciseKey.isEmpty
          ? ExerciseKeyUtil.make(exercise.exerciseName)
          : exercise.exerciseKey;
      if (effectiveKey != args.exerciseKey) continue;
      final localBest = PrCalculator.bestEstimatedOneRm(exercise.sets);
      if (localBest > best) best = localBest;
    }
  }
  return best;
});

class WorkoutActions {
  const WorkoutActions();

  Future<void> createWorkoutTemplate(WorkoutTemplate template) {
    return DatabaseService.insertWorkoutTemplate(template);
  }

  Future<void> updateWorkoutTemplate(WorkoutTemplate template) {
    return DatabaseService.updateWorkoutTemplate(template);
  }

  Future<void> deleteWorkoutTemplate(String id) {
    return DatabaseService.deleteWorkoutTemplate(id);
  }

  Future<void> createExerciseTemplate(ExerciseTemplate template) {
    return DatabaseService.insertExerciseTemplate(template);
  }

  Future<void> updateExerciseTemplate(ExerciseTemplate template) {
    return DatabaseService.updateExerciseTemplate(template);
  }

  Future<void> deleteExerciseTemplate(String id) {
    return DatabaseService.deleteExerciseTemplate(id);
  }

  Future<void> createWorkoutSession(WorkoutSession session) {
    return DatabaseService.insertWorkoutSession(session);
  }

  Future<void> updateWorkoutSession(WorkoutSession session) {
    return DatabaseService.updateWorkoutSession(session);
  }

  Future<void> deleteWorkoutSession(String id) {
    return DatabaseService.deleteWorkoutSession(id);
  }

  Future<void> createExerciseLog(ExerciseLog log) {
    return DatabaseService.insertExerciseLog(log);
  }

  Future<void> updateExerciseLog(ExerciseLog log) {
    return DatabaseService.updateExerciseLog(log);
  }

  Future<void> deleteExerciseLog(String id) {
    return DatabaseService.deleteExerciseLog(id);
  }

  Future<void> createSetLog(SetLog log) {
    return DatabaseService.insertSetLog(log);
  }

  Future<void> updateSetLog(SetLog log) {
    return DatabaseService.updateSetLog(log);
  }

  Future<void> deleteSetLog(String id) {
    return DatabaseService.deleteSetLog(id);
  }
}

Future<List<WorkoutSession>> _loadWorkoutSessionsWithLogs() async {
  final sessions = await DatabaseService.getWorkoutSessions();
  final result = <WorkoutSession>[];
  for (final session in sessions) {
    final exercises = await _loadExerciseLogsWithSets(session.id);
    result.add(session.copyWith(exerciseLogs: exercises));
  }
  return result;
}

Future<List<ExerciseLog>> _loadExerciseLogsWithSets(String sessionId) async {
  final logs = await DatabaseService.getExerciseLogsBySession(sessionId);
  final result = <ExerciseLog>[];
  for (final log in logs) {
    final sets = await DatabaseService.getSetLogsByExercise(log.id);
    result.add(log.copyWith(sets: sets));
  }
  return result;
}
