import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';
import '../theme/app_theme.dart';
import '../utils/index.dart';
import '../providers/index.dart';
import 'workout_execution_screen.dart';

class PreWorkoutScreen extends ConsumerWidget {
  final WorkoutTemplate workout;

  const PreWorkoutScreen({required this.workout, Key? key}) : super(key: key);

  Future<void> _startWorkout(
    BuildContext context,
    WidgetRef ref,
    List<ExerciseTemplate> exercises,
  ) async {
    final sessions = await ref.read(workoutSessionsWithLogsProvider.future);
    final inProgressSessions = sessions
        .where((s) =>
            (s.workoutTemplateId == workout.id || s.workoutName == workout.name) &&
            VolumeCalculator.isRecoverableInProgress(s))
        .toList();

    if (!context.mounted) return;

    if (inProgressSessions.isNotEmpty) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutExecutionScreen(session: inProgressSessions.first),
        ),
      );
      if (!context.mounted) return;
      if (result == true) {
        ref.invalidate(workoutSessionsWithLogsProvider);
        Navigator.pop(context, true);
      }
      return;
    }

    final session = WorkoutSession(
      id: const Uuid().v4(),
      workoutTemplateId: workout.id,
      workoutName: workout.name,
      date: DateTime.now(),
    );

    await ref.read(workoutActionsProvider).createWorkoutSession(session);

    for (final exercise in exercises) {
      final exerciseLog = ExerciseLog(
        id: const Uuid().v4(),
        exerciseName: exercise.name,
        exerciseKey: exercise.effectiveExerciseKey,
        order: exercise.order,
        notes: exercise.defaultNotes,
        repRange: exercise.defaultRepRange,
        workoutSessionId: session.id,
      );
      await ref.read(workoutActionsProvider).createExerciseLog(exerciseLog);
    }

    if (!context.mounted) return;
    ref.invalidate(workoutSessionsWithLogsProvider);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => WorkoutExecutionScreen(session: session)),
    );

    if (!context.mounted) return;
    if (result == true) Navigator.pop(context, true);
  }

  Future<void> _createExercise(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final repRangeController = TextEditingController();

    final result = await showDialog<ExerciseTemplate>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar exercício'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Nome do exercício'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repRangeController,
                decoration: const InputDecoration(hintText: 'Faixa de reps (ex: 5-8)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final exercise = ExerciseTemplate(
                id: const Uuid().v4(),
                name: nameController.text,
                exerciseKey: ExerciseKeyUtil.make(nameController.text),
                workoutTemplateId: workout.id,
                workoutName: workout.name,
                order: 0,
                defaultRepRange: repRangeController.text,
              );
              Navigator.pop(context, exercise);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(workoutActionsProvider).createExerciseTemplate(result);
      ref.invalidate(exerciseTemplatesProvider(workout.name));
    }

    nameController.dispose();
    repRangeController.dispose();
  }

  Future<void> _editExercise(
    BuildContext context,
    WidgetRef ref,
    ExerciseTemplate exercise,
  ) async {
    final nameController = TextEditingController(text: exercise.name);
    final repRangeController = TextEditingController(text: exercise.defaultRepRange);

    final result = await showDialog<ExerciseTemplate>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar exercício'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Nome do exercício'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repRangeController,
                decoration: const InputDecoration(hintText: 'Faixa de reps (ex: 5-8)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final updated = exercise.copyWith(
                name: nameController.text,
                exerciseKey: ExerciseKeyUtil.make(nameController.text),
                defaultRepRange: repRangeController.text,
              );
              Navigator.pop(context, updated);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(workoutActionsProvider).updateExerciseTemplate(result);
      ref.invalidate(exerciseTemplatesProvider(workout.name));
    }

    nameController.dispose();
    repRangeController.dispose();
  }

  Future<void> _deleteExercise(
    BuildContext context,
    WidgetRef ref,
    ExerciseTemplate exercise,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar exercício?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(workoutActionsProvider).deleteExerciseTemplate(exercise.id);
      ref.invalidate(exerciseTemplatesProvider(workout.name));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exerciseTemplatesProvider(workout.name));
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(workout.name)),
      body: exercisesAsync.when(
        data: (exercises) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start button — primary CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: exercises.isEmpty
                      ? null
                      : () => _startWorkout(context, ref, exercises),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text('Iniciar treino'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Text(
                    'Exercícios',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _createExercise(context, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Adicionar'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      textStyle:
                          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (exercises.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Nenhum exercício. Adicione o primeiro para começar.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return _ExerciseTemplateCard(
                      exercise: exercise,
                      index: index,
                      onEdit: () => _editExercise(context, ref, exercise),
                      onDelete: () => _deleteExercise(context, ref, exercise),
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }
}

enum _ExerciseMenuAction { edit, delete }

class _ExerciseTemplateCard extends StatelessWidget {
  final ExerciseTemplate exercise;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseTemplateCard({
    required this.exercise,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (exercise.defaultRepRange.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${exercise.defaultRepRange} reps',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ),
                  if (exercise.defaultNotes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        exercise.defaultNotes,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<_ExerciseMenuAction>(
              icon: Icon(Icons.more_vert_rounded, size: 18, color: colors.onSurfaceVariant),
              onSelected: (value) {
                switch (value) {
                  case _ExerciseMenuAction.edit:
                    onEdit();
                    return;
                  case _ExerciseMenuAction.delete:
                    onDelete();
                    return;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: _ExerciseMenuAction.edit, child: Text('Editar')),
                PopupMenuItem(value: _ExerciseMenuAction.delete, child: Text('Apagar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
