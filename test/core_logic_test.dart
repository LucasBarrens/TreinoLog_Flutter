import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/models/index.dart';
import 'package:gymlog/utils/index.dart';

void main() {
  group('FormattingUtil', () {
    test('formats date and time consistently', () {
      final date = DateTime(2026, 5, 29, 14, 7);

      expect(FormattingUtil.formatDate(date), '29/05/2026');
      expect(FormattingUtil.formatTime(date), '14:07');
    });

    test('parses and formats weight values', () {
      expect(FormattingUtil.parseWeight('80,5'), 80.5);
      expect(FormattingUtil.formatWeight(80.0), '80');
      expect(FormattingUtil.formatWeight(80.5), '80.5');
    });
  });

  group('ExerciseKeyUtil', () {
    test('normalizes exercise names into stable keys', () {
      expect(ExerciseKeyUtil.make('Supino Inclinado Halter'), 'supino-inclinado-halter');
      expect(ExerciseKeyUtil.make('Puxada Frente triangulo!'), 'puxada-frente-triangulo');
    });
  });

  group('VolumeCalculator', () {
    test('calculates volume and set counts', () {
      final session = WorkoutSession(
        id: 'session-1',
        workoutTemplateId: 'workout-1',
        workoutName: 'Upper A',
        date: DateTime(2026, 5, 29, 10, 0),
        exerciseLogs: [
          ExerciseLog(
            id: 'exercise-1',
            exerciseName: 'Supino',
            order: 0,
            sets: [
              SetLog(id: 'set-1', setNumber: 1, weightKg: 80, reps: 8),
              SetLog(id: 'set-2', setNumber: 2, weightKg: 82.5, reps: 6),
            ],
          ),
          ExerciseLog(
            id: 'exercise-2',
            exerciseName: 'Remada',
            order: 1,
            sets: [
              SetLog(id: 'set-3', setNumber: 1, weightKg: 70, reps: 10),
            ],
          ),
        ],
      );

      expect(VolumeCalculator.countTotalSets(session), 3);
      expect(VolumeCalculator.countStartedExercises(session), 2);
      expect(VolumeCalculator.calculateSessionVolume(session), 1835);
    });

    test('finds best set by weight and reps', () {
      final best = VolumeCalculator.findBestSet([
        SetLog(id: 'set-1', setNumber: 1, weightKg: 80, reps: 8),
        SetLog(id: 'set-2', setNumber: 2, weightKg: 80, reps: 10),
        SetLog(id: 'set-3', setNumber: 3, weightKg: 82.5, reps: 6),
      ]);

      expect(best?.id, 'set-3');
    });
  });

  group('ExerciseLog', () {
    test('derives status from completion and sets', () {
      final empty = ExerciseLog(
        id: 'exercise-1',
        exerciseName: 'Supino',
        order: 0,
      );
      final inProgress = ExerciseLog(
        id: 'exercise-2',
        exerciseName: 'Remada',
        order: 1,
        sets: [
          SetLog(id: 'set-1', setNumber: 1, weightKg: 70, reps: 8),
        ],
      );
      final completed = ExerciseLog(
        id: 'exercise-3',
        exerciseName: 'Crucifixo',
        order: 2,
        isCompleted: true,
      );

      expect(empty.status, ExerciseStatus.notStarted);
      expect(inProgress.status, ExerciseStatus.inProgress);
      expect(completed.status, ExerciseStatus.completed);
    });
  });
}
