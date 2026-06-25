import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../theme/app_theme.dart';
import '../utils/index.dart';
import '../providers/index.dart';

class WorkoutFinalSummaryScreen extends ConsumerWidget {
  final WorkoutSession session;
  final DateTime finishedAt;

  const WorkoutFinalSummaryScreen({
    required this.session,
    required this.finishedAt,
    Key? key,
  }) : super(key: key);

  Future<void> _conclude(BuildContext context, WidgetRef ref) async {
    final updatedSession = session.copyWith(finishedAt: finishedAt, isFinished: true);
    await ref.read(workoutActionsProvider).updateWorkoutSession(updatedSession);
    HapticFeedback.lightImpact();
    if (!context.mounted) return;
    ref.invalidate(workoutSessionsWithLogsProvider);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exerciseLogsProvider(session.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Treino finalizado')),
      body: exercisesAsync.when(
        data: (exercises) {
          final sessionData = session.copyWith(
            exerciseLogs: exercises,
            finishedAt: finishedAt,
            isFinished: true,
          );
          final totalSets = VolumeCalculator.countTotalSets(sessionData);
          final startedExercises = VolumeCalculator.countStartedExercises(sessionData);
          final totalVolume = VolumeCalculator.calculateSessionVolume(sessionData);
          final duration = VolumeCalculator.formatDuration(sessionData.startDate, finishedAt);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header congratulation
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.successMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        session.workoutName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Treino concluído',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Resultado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SummaryTile(
                      icon: Icons.timer_outlined,
                      label: 'Duração',
                      value: duration,
                    ),
                    const SizedBox(width: 10),
                    _SummaryTile(
                      icon: Icons.layers_rounded,
                      label: 'Séries',
                      value: '$totalSets',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _SummaryTile(
                      icon: Icons.fitness_center_rounded,
                      label: 'Exercícios',
                      value: '$startedExercises',
                    ),
                    const SizedBox(width: 10),
                    _SummaryTile(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Volume',
                      value: '${FormattingUtil.formatWeight(totalVolume)} kg',
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _conclude(context, ref),
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text('Salvar e concluir'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: AppColors.success,
                      textStyle:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
