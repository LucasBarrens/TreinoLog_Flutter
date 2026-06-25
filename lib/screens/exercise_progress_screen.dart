import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../utils/index.dart';
import '../providers/index.dart';
import '../widgets/progression_chart.dart';

class ExerciseProgressScreen extends ConsumerWidget {
  final String exerciseName;
  final String exerciseKey;

  const ExerciseProgressScreen({
    required this.exerciseName,
    required this.exerciseKey,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseKey));

    return Scaffold(
      appBar: AppBar(title: Text(exerciseName)),
      body: historyAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Sem evolução registrada',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Conclua treinos com este exercício para ver sua evolução.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final bestSetOverall = VolumeCalculator.findBestSet(
            entries.expand((e) => e.sets).toList(),
          );

          double maxWeight = 0.0;
          if (bestSetOverall != null) {
            for (final entry in entries) {
              for (final set in entry.sets) {
                if (set.weightKg > maxWeight) {
                  maxWeight = set.weightKg;
                }
              }
            }
          }

          final lastWorkoutBestSet = entries.isNotEmpty
              ? VolumeCalculator.findBestSet(entries.first.sets)
              : null;
          final totalSessions = entries.length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumo',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ProgressStat(
                            label: 'Melhor carga',
                            value: maxWeight > 0
                                ? '${FormattingUtil.formatWeight(maxWeight)}kg'
                                : '-',
                          ),
                          _ProgressStat(
                            label: 'Melhor série',
                            value: bestSetOverall != null
                                ? '${FormattingUtil.formatWeight(bestSetOverall.weightKg)}kg x ${bestSetOverall.reps}'
                                : '-',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ProgressStat(
                            label: 'Último treino',
                            value: lastWorkoutBestSet != null
                                ? '${FormattingUtil.formatWeight(lastWorkoutBestSet.weightKg)}kg x ${lastWorkoutBestSet.reps}'
                                : '-',
                          ),
                          _ProgressStat(
                            label: 'Sessões',
                            value: '$totalSessions',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ProgressionChart(entries: entries),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Histórico Recente',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = entries[index];
                    final sessionBestSet = VolumeCalculator.findBestSet(entry.sets);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                FormattingUtil.formatDate(entry.session.date),
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              if (sessionBestSet != null)
                                Text(
                                  '${FormattingUtil.formatWeight(sessionBestSet.weightKg)}kg x ${sessionBestSet.reps}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              else
                                Text(
                                  'Nenhuma série registrada',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: entries.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProgressStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
