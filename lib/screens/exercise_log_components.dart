import 'package:flutter/material.dart';

import '../models/index.dart';
import '../theme/app_theme.dart';
import '../utils/index.dart';

class ProgressionCard extends StatelessWidget {
  final List<SetLog> sets;
  final SetLog? lastWorkoutBestSet;
  final VoidCallback onViewHistory;

  const ProgressionCard({
    required this.sets,
    required this.onViewHistory,
    this.lastWorkoutBestSet,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lastBest = lastWorkoutBestSet;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sugestão para hoje',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                GestureDetector(
                  onTap: onViewHistory,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 15, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Histórico',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lastBest != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Último treino',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${FormattingUtil.formatWeight(lastBest.weightKg)} kg × ${lastBest.reps}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _suggestion(lastBest),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ] else
              Text(
                'Sem histórico ainda. Registre suas primeiras séries.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  String _suggestion(SetLog lastSet) {
    if (lastSet.weightKg == 0) return 'Registre sua primeira série para receber sugestão.';
    if (lastSet.reps >= 10) {
      return 'Você atingiu muitas repetições. Considere subir a carga.';
    }
    return 'Tente ${FormattingUtil.formatWeight(lastSet.weightKg)} kg × ${lastSet.reps + 1}. '
        'Se atingir facilmente, considere subir a carga.';
  }
}

// ── Rest Timer ────────────────────────────────────────────────────────────────

class RestTimerCard extends StatelessWidget {
  final int remainingRestSeconds;
  final bool isTimerRunning;
  final int lastRestPreset;
  final List<int> restPresets;
  final VoidCallback onToggleTimer;
  final VoidCallback onResetTimer;
  final ValueChanged<int> onPresetSelected;

  const RestTimerCard({
    required this.remainingRestSeconds,
    required this.isTimerRunning,
    required this.lastRestPreset,
    required this.restPresets,
    required this.onToggleTimer,
    required this.onResetTimer,
    required this.onPresetSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = remainingRestSeconds ~/ 60;
    final seconds = remainingRestSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final totalSeconds = lastRestPreset;
    final progressPercent =
        totalSeconds > 0 ? 1.0 - (remainingRestSeconds / totalSeconds) : 0.0;
    final isDone = remainingRestSeconds == 0;
    final progressColor = isDone ? AppColors.success : AppColors.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.hourglass_bottom_rounded,
                    size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Descanso',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                // Preset chips
                Wrap(
                  spacing: 6,
                  children: restPresets.map((preset) {
                    final isActive = preset == lastRestPreset && remainingRestSeconds > 0;
                    return GestureDetector(
                      onTap: () => onPresetSelected(preset),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: isActive
                              ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                              : null,
                        ),
                        child: Text(
                          '${preset}s',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: progressPercent,
                        strokeWidth: 5,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .outlineVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                    Text(
                      timeText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: isDone ? AppColors.success : null,
                          ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: remainingRestSeconds > 0 ? onToggleTimer : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Text(isTimerRunning ? 'Pausar' : 'Continuar'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: remainingRestSeconds > 0 ? onResetTimer : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(
                              color: AppColors.danger,
                              width: 1.2,
                            ),
                          ),
                          child: const Text('Resetar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notes Field ───────────────────────────────────────────────────────────────

class ExerciseNotesField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const ExerciseNotesField({required this.controller, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Observações',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Adicione observações sobre este exercício',
              ),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
