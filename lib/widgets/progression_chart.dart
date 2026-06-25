import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/index.dart';
import '../utils/index.dart';

class ProgressionChart extends StatelessWidget {
  final List<ExerciseHistoryEntry> entries;

  const ProgressionChart({
    required this.entries,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEntries = [...entries]..sort(
        (a, b) => a.session.date.compareTo(b.session.date),
      );

    if (sortedEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    final points = <_ChartPoint>[];
    for (final entry in sortedEntries) {
      final bestSet = VolumeCalculator.findBestSet(entry.sets);
      if (bestSet == null) continue;
      points.add(
        _ChartPoint(
          sessionDate: entry.session.date,
          value: bestSet.weightKg,
        ),
      );
    }

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final values = points.map((point) => point.value).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final paddedMin = math.max(0.0, minValue - 2);
    final paddedMax = maxValue + 2.0;
    final spots = points
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(
            entry.key.toDouble(),
            entry.value.value,
          ),
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progressão da carga',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Melhor série por sessão',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: math.max(0, spots.length - 1).toDouble(),
                  minY: paddedMin.toDouble(),
                  maxY: paddedMax.toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval:
                        _horizontalInterval(paddedMin.toDouble(), paddedMax.toDouble()),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.25),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval:
                            _horizontalInterval(paddedMin.toDouble(), paddedMax.toDouble()),
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              FormattingUtil.formatWeight(value.toDouble()),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }

                          final shouldShow = index == 0 ||
                              index == points.length - 1 ||
                              points.length <= 3 ||
                              index % 2 == 0;
                          if (!shouldShow) {
                            return const SizedBox.shrink();
                          }

                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              FormattingUtil.formatDate(points[index].sessionDate),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.round();
                          if (index < 0 || index >= points.length) {
                            return null;
                          }

                          final point = points[index];
                          return LineTooltipItem(
                            '${FormattingUtil.formatWeight(point.value)}kg\n'
                            '${FormattingUtil.formatDate(point.sessionDate)}',
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                ) ??
                                const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _horizontalInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) {
      return 1;
    }
    return math.max(1, range / 4);
  }
}

class _ChartPoint {
  final DateTime sessionDate;
  final double value;

  _ChartPoint({
    required this.sessionDate,
    required this.value,
  });
}
