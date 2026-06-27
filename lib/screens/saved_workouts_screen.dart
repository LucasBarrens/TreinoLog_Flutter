import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../theme/app_theme.dart';
import '../providers/index.dart';
import '../utils/index.dart';
import 'exercise_progress_screen.dart';

class SavedWorkoutsScreen extends ConsumerWidget {
  const SavedWorkoutsScreen({Key? key}) : super(key: key);

  List<WorkoutSessionGroup> _groupSessions(List<WorkoutSession> sessions) {
    final filtered = sessions
        .where((s) => s.isFinished && VolumeCalculator.hasRegisteredSets(s))
        .toList();

    final grouped = <DateTime, List<WorkoutSession>>{};
    for (final session in filtered) {
      final dayKey = DateTime(session.date.year, session.date.month, session.date.day);
      grouped.putIfAbsent(dayKey, () => []).add(session);
    }

    final groups = grouped.entries
        .map((e) => WorkoutSessionGroup(
              day: e.key,
              sessions: e.value..sort((a, b) => b.date.compareTo(a.date)),
            ))
        .toList();

    groups.sort((a, b) => b.day.compareTo(a.day));
    return groups;
  }

  Future<void> _deleteSession(
      BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar treino?'),
        content: const Text(
          'Remove esta sessão e todas as séries vinculadas. '
          'Templates não serão apagados.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(workoutActionsProvider).deleteWorkoutSession(session.id);
      ref.invalidate(workoutSessionsWithLogsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(workoutSessionsWithLogsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: sessionsAsync.when(
        data: (sessions) {
          final groups = _groupSessions(sessions);

          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 48, color: colors.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Sem treinos registrados',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                  const SizedBox(height: 8),
                  Text(
                    'Os treinos finalizados aparecerão aqui.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: groups.length,
            itemBuilder: (context, groupIndex) {
              final group = groups[groupIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                    child: Text(
                      FormattingUtil.formatDate(group.day),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                  ...group.sessions.map((session) {
                    final sets = VolumeCalculator.countTotalSets(session);
                    final volume = VolumeCalculator.calculateSessionVolume(session);
                    final duration = VolumeCalculator.formatDuration(
                      session.startDate,
                      session.finishedAt,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showSessionDetails(context, session),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.workoutName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _Chip(
                                          icon: Icons.timer_outlined,
                                          label: duration,
                                        ),
                                        const SizedBox(width: 8),
                                        _Chip(
                                          icon: Icons.layers_rounded,
                                          label: '$sets séries',
                                        ),
                                        const SizedBox(width: 8),
                                        _Chip(
                                          icon: Icons.monitor_weight_outlined,
                                          label:
                                              '${FormattingUtil.formatWeight(volume)}kg',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<_SavedWorkoutMenuAction>(
                                icon: Icon(Icons.more_vert_rounded,
                                    size: 18, color: colors.onSurfaceVariant),
                                onSelected: (value) {
                                  switch (value) {
                                    case _SavedWorkoutMenuAction.details:
                                      _showSessionDetails(context, session);
                                      return;
                                    case _SavedWorkoutMenuAction.delete:
                                      _deleteSession(context, ref, session);
                                      return;
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                      value: _SavedWorkoutMenuAction.details,
                                      child: Text('Detalhes')),
                                  PopupMenuItem(
                                      value: _SavedWorkoutMenuAction.delete,
                                      child: Text('Apagar')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  void _showSessionDetails(BuildContext context, WorkoutSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SessionDetailsSheet(session: session),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: colors.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

enum _SavedWorkoutMenuAction { details, delete }

class WorkoutSessionGroup {
  final DateTime day;
  final List<WorkoutSession> sessions;
  WorkoutSessionGroup({required this.day, required this.sessions});
}

class _SessionDetailsSheet extends StatelessWidget {
  final WorkoutSession session;
  const _SessionDetailsSheet({required this.session});

  @override
  Widget build(BuildContext context) {
    final totalSets = VolumeCalculator.countTotalSets(session);
    final volume = VolumeCalculator.calculateSessionVolume(session);
    final duration = VolumeCalculator.formatDuration(session.startDate, session.finishedAt);
    final colors = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const SizedBox(height: 8),
          Text(
            session.workoutName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            FormattingUtil.formatDate(session.date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _DetailTile(icon: Icons.timer_outlined, label: 'Duração', value: duration),
              const SizedBox(width: 10),
              _DetailTile(icon: Icons.layers_rounded, label: 'Séries', value: '$totalSets'),
              const SizedBox(width: 10),
              _DetailTile(
                icon: Icons.monitor_weight_outlined,
                label: 'Volume',
                value: '${FormattingUtil.formatWeight(volume)}kg',
              ),
            ],
          ),
          if (session.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Observações',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              session.notes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
          if (session.exerciseLogs.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Exercícios',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            ...session.exerciseLogs.map((log) {
              if (log.sets.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => ExerciseProgressScreen(
                          exerciseName: log.exerciseName,
                          exerciseKey: ExerciseKeyUtil.make(log.exerciseName),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.exerciseName,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                log.sets
                                    .map((s) =>
                                        '${FormattingUtil.formatWeight(s.weightKg)}kg×${s.reps}')
                                    .join('  '),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 16, color: colors.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 15, color: colors.primary),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
