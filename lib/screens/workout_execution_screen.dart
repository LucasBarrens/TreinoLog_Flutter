import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../theme/app_theme.dart';
import '../utils/index.dart';
import '../providers/index.dart';
import 'exercise_log_screen.dart';
import 'workout_final_summary_screen.dart';

class WorkoutExecutionScreen extends ConsumerStatefulWidget {
  final WorkoutSession session;

  const WorkoutExecutionScreen({required this.session, Key? key}) : super(key: key);

  @override
  ConsumerState<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends ConsumerState<WorkoutExecutionScreen> {
  late WorkoutSession _session;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

  Future<void> _updateNotes() async {
    final controller = TextEditingController(text: _session.notes);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Observações do treino'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Adicione observações sobre o treino'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != null) {
      _session = _session.copyWith(notes: result);
      await ref.read(workoutActionsProvider).updateWorkoutSession(_session);
      ref.invalidate(exerciseLogsProvider(_session.id));
    }

    controller.dispose();
  }

  Future<void> _finishWorkout(List<ExerciseLog> exercises) async {
    final totalSets = exercises.fold<int>(0, (sum, e) => sum + e.sets.length);

    if (totalSets == 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nenhuma série registrada'),
          content: const Text('Deseja descartar este treino?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _discardWorkout();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutFinalSummaryScreen(
          session: _session,
          finishedAt: DateTime.now(),
        ),
      ),
    );

    if (!mounted) return;
    if (result == true) Navigator.pop(context, true);
  }

  Future<void> _discardWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar treino?'),
        content: const Text('Todas as séries registradas serão perdidas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(workoutActionsProvider).deleteWorkoutSession(_session.id);
      if (!mounted) return;
      ref.invalidate(workoutSessionsWithLogsProvider);
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseLogsProvider(_session.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(_session.workoutName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'Observações',
            onPressed: _updateNotes,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: exercisesAsync.when(
        data: (exercises) {
          final totalSets = exercises.fold<int>(0, (sum, e) => sum + e.sets.length);
          final completedExercises = exercises.where((e) => e.isCompleted).length;
          final totalVolume = VolumeCalculator.calculateSessionVolume(_session);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatsGrid(
                  totalSets: totalSets,
                  completedExercises: completedExercises,
                  totalExercises: exercises.length,
                  totalVolume: totalVolume,
                  startDate: _session.startDate,
                ),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Exercícios'),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return _ExerciseCard(
                      exercise: exercise,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExerciseLogScreen(exerciseLog: exercise),
                          ),
                        );
                        ref.invalidate(exerciseLogsProvider(_session.id));
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _finishWorkout(exercises),
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text('Finalizar treino'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _discardWorkout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger, width: 1.5),
                    ),
                    child: const Text('Descartar treino'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
    );
  }
}

// ── Stats Grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final int totalSets;
  final int completedExercises;
  final int totalExercises;
  final double totalVolume;
  final DateTime startDate;

  const _StatsGrid({
    required this.totalSets,
    required this.completedExercises,
    required this.totalExercises,
    required this.totalVolume,
    required this.startDate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.layers_rounded,
            label: 'Séries',
            value: '$totalSets',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.check_circle_outline_rounded,
            label: 'Exercícios',
            value: '$completedExercises/$totalExercises',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.timer_outlined,
            label: 'Duração',
            value: VolumeCalculator.formatDuration(startDate),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.monitor_weight_outlined,
            label: 'Volume',
            value: '${FormattingUtil.formatWeight(totalVolume)}kg',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exercise Card ─────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final ExerciseLog exercise;
  final VoidCallback onTap;

  const _ExerciseCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = exercise.status;
    final colors = Theme.of(context).colorScheme;

    // Sets with reps > 0 count as "done"
    final doneSets = exercise.sets.where((s) => s.reps > 0).length;
    final totalSets = exercise.sets.length;

    // Progress: 0.0 → 1.0
    // If exercise is completed, fill to 100% regardless.
    final double progress = exercise.isCompleted
        ? 1.0
        : (totalSets == 0 ? 0.0 : doneSets / totalSets);

    String subtitle = '';
    if (status == ExerciseStatus.notStarted) {
      subtitle = 'Toque para registrar';
    } else {
      subtitle = exercise.sets
          .map((s) => '${FormattingUtil.formatWeight(s.weightKg)}kg×${s.reps}')
          .join('  ');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Progress circle
              _SetProgressRing(
                progress: progress,
                doneSets: doneSets,
                totalSets: totalSets,
                isCompleted: exercise.isCompleted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetProgressRing extends StatelessWidget {
  final double progress;
  final int doneSets;
  final int totalSets;
  final bool isCompleted;

  const _SetProgressRing({
    required this.progress,
    required this.doneSets,
    required this.totalSets,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final Color trackColor = Theme.of(context).colorScheme.outlineVariant;
    final Color progressColor = isCompleted
        ? AppColors.success
        : (progress > 0 ? AppColors.success : trackColor);

    final String label = isCompleted
        ? '✓'
        : (totalSets == 0 ? '—' : '$doneSets/$totalSets');

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompleted ? 14 : 11,
              fontWeight: FontWeight.w700,
              color: progress > 0 ? AppColors.success : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
