import 'package:uuid/uuid.dart';
import '../models/index.dart';
import '../utils/index.dart';
import 'database_service.dart';

class SeedDataService {
  static const uuid = Uuid();

  // 4x/week fullbody — works for men and women, beginner to intermediate
  // Rotate: A → B → C → D → repeat
  static const seedWorkouts = [
    (
      name: 'Upper A',
      exercises: [
        'Supino Inclinado Halter',
        'Crucifixo Máquina',
        'Remada Baixa Cabo',
        'Puxada Frente Triângulo',
        'Desenvolvimento Máquina',
        'Tríceps Polia',
        'Bíceps Polia',
      ]
    ),
    (
      name: 'Lower A',
      exercises: [
        'Terra Romeno',
        'RDL Halteres',
        'Mesa Flexora',
        'Cadeira Extensora',
        'Panturrilha em Pé',
      ]
    ),
    (
      name: 'Upper B',
      exercises: [
        'Remada Apoio de Peito',
        'Puxada Frente Triângulo',
        'Supino Inclinado Smith',
        'Crucifixo Máquina',
        'Desenvolvimento Máquina',
        'Elevação Lateral Cabo',
        'Tríceps Corda',
        'Rosca Bayesian',
      ]
    ),
    (
      name: 'Lower B',
      exercises: [
        'Agachamento Livre',
        'Leg Press',
        'Cadeira Extensora',
        'Mesa Flexora',
        'Panturrilha Máquina',
      ]
    ),
  ];

  static Future<void> ensureInitialData() async {
    final existing = await DatabaseService.getWorkoutTemplates();
    if (existing.isNotEmpty) {
      return;
    }

    for (int workoutIndex = 0; workoutIndex < seedWorkouts.length; workoutIndex++) {
      final workout = seedWorkouts[workoutIndex];
      final template = WorkoutTemplate(
        id: uuid.v4(),
        name: workout.name,
        order: workoutIndex,
      );

      await DatabaseService.insertWorkoutTemplate(template);

      for (int exerciseIndex = 0; exerciseIndex < workout.exercises.length; exerciseIndex++) {
        final exerciseName = workout.exercises[exerciseIndex];
        final repRange = _defaultRepRange(exerciseName);

        final exercise = ExerciseTemplate(
          id: uuid.v4(),
          name: exerciseName,
          exerciseKey: ExerciseKeyUtil.make(exerciseName),
          workoutTemplateId: template.id,
          workoutName: workout.name,
          order: exerciseIndex,
          defaultRepRange: repRange,
          defaultNotes: '',
        );

        await DatabaseService.insertExerciseTemplate(exercise);
      }
    }
  }

  static String _defaultRepRange(String exerciseName) {
    final key = ExerciseKeyUtil.make(exerciseName);

    if (key == 'agachamento-livre') return '4-6';
    if (key == 'rdl-halteres') return '6-8';
    
    if (key.contains('panturrilha')) {
      return '12-20';
    }

    if (key.contains('elevacao-lateral') ||
        key.contains('crucifixo') ||
        key.contains('rosca') ||
        key.contains('triceps')) {
      return '10-15';
    }

    if (key.contains('leg-press') ||
        key.contains('cadeira') ||
        key.contains('mesa') ||
        key.contains('supino') ||
        key.contains('puxada') ||
        key.contains('remada') ||
        key.contains('desenvolvimento')) {
      return '5-9';
    }

    // Compound lifts
    return '6-12';
  }
}
