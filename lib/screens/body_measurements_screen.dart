import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/index.dart';
import '../providers/index.dart';
import '../theme/app_theme.dart';
import '../utils/index.dart';
import 'body_measurement_form_screen.dart';

class BodyMeasurementsScreen extends ConsumerWidget {
  const BodyMeasurementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurementsAsync = ref.watch(bodyMeasurementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medidas Corporais'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova medição'),
      ),
      body: measurementsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState();
          }
          // Already sorted by date DESC at the DB layer. previous = the next
          // entry in the same list.
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final current = items[index];
              final previous = index + 1 < items.length ? items[index + 1] : null;
              return _MeasurementCard(
                measurement: current,
                previous: previous,
                onTap: () => _openForm(context, existing: current),
                onDelete: () => _confirmDelete(context, ref, current),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {BodyMeasurement? existing}) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BodyMeasurementFormScreen(existing: existing),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BodyMeasurement m,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar medição?'),
        content: Text(
          'A medição de ${FormattingUtil.formatDate(m.date)} será apagada. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(bodyMeasurementActionsProvider).delete(m.id);
    ref.invalidate(bodyMeasurementsProvider);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.straighten_rounded,
                  color: colors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma medição ainda',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Toque em "Nova medição" para começar seu histórico.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final BodyMeasurement measurement;
  final BodyMeasurement? previous;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MeasurementCard({
    required this.measurement,
    required this.previous,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    FormattingUtil.formatDate(measurement.date),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      measurement.sex.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<_CardAction>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: colors.onSurfaceVariant, size: 20),
                    onSelected: (a) {
                      switch (a) {
                        case _CardAction.edit:
                          onTap();
                          return;
                        case _CardAction.delete:
                          onDelete();
                          return;
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: _CardAction.edit, child: Text('Editar')),
                      PopupMenuItem(
                          value: _CardAction.delete, child: Text('Apagar')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _PrimaryStats(m: measurement),
              ),
              if (previous != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _DeltaRow(current: measurement, previous: previous!),
                ),
              ],
              if (measurement.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    measurement.notes,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _CardAction { edit, delete }

class _PrimaryStats extends StatelessWidget {
  final BodyMeasurement m;
  const _PrimaryStats({required this.m});

  @override
  Widget build(BuildContext context) {
    final stats = <_StatTile>[];
    if (m.weightKg != null) {
      stats.add(_StatTile(label: 'Peso', value: '${_fmt(m.weightKg)} kg'));
    }
    if (m.heightCm != null) {
      stats.add(_StatTile(label: 'Altura', value: '${_fmt(m.heightCm)} cm'));
    }
    if (m.waistCm != null) {
      stats.add(_StatTile(label: 'Cintura', value: '${_fmt(m.waistCm)} cm'));
    }
    if (m.chestCm != null) {
      stats.add(_StatTile(label: 'Tórax', value: '${_fmt(m.chestCm)} cm'));
    }
    if (m.averageBicepsCm != null) {
      stats.add(_StatTile(
          label: 'Braço', value: '${_fmt(m.averageBicepsCm)} cm'));
    }
    if (m.hipOrGlutesCm != null) {
      stats.add(_StatTile(
          label: m.glutesCm != null ? 'Glúteos' : 'Quadril',
          value: '${_fmt(m.hipOrGlutesCm)} cm'));
    }

    if (stats.isEmpty) {
      return Text(
        'Sem valores registrados.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: stats,
    );
  }

  String _fmt(double? v) {
    if (v == null) return '—';
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DeltaRow extends StatelessWidget {
  final BodyMeasurement current;
  final BodyMeasurement previous;
  const _DeltaRow({required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final deltas = <_DeltaChip>[];

    void addDelta(String label, double? a, double? b, String unit) {
      if (a == null || b == null) return;
      final diff = a - b;
      if (diff == 0) return;
      deltas.add(_DeltaChip(label: label, diff: diff, unit: unit));
    }

    addDelta('Peso', current.weightKg, previous.weightKg, 'kg');
    addDelta('Cintura', current.waistCm, previous.waistCm, 'cm');
    addDelta('Tórax', current.chestCm, previous.chestCm, 'cm');
    addDelta('Braço', current.averageBicepsCm, previous.averageBicepsCm, 'cm');
    addDelta(
      current.glutesCm != null && previous.glutesCm != null
          ? 'Glúteos'
          : 'Quadril',
      current.hipOrGlutesCm,
      previous.hipOrGlutesCm,
      'cm',
    );

    if (deltas.isEmpty) {
      return Text(
        'Sem variação detectada vs. medição anterior.',
        style: TextStyle(
          fontSize: 11,
          color: colors.onSurfaceVariant,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.compare_arrows_rounded,
            size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: deltas,
          ),
        ),
      ],
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final String label;
  final double diff;
  final String unit;
  const _DeltaChip({
    required this.label,
    required this.diff,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = diff > 0;
    final color = isUp ? AppColors.success : AppColors.danger;
    final muted = isUp ? AppColors.successMuted : AppColors.dangerMuted;
    final sign = isUp ? '+' : '−';
    final magnitude = diff.abs();
    final formatted = magnitude == magnitude.roundToDouble()
        ? magnitude.toStringAsFixed(0)
        : magnitude.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: muted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label  $sign$formatted $unit',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
