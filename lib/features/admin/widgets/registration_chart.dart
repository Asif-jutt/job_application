import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/extensions.dart';
import '../provider/admin_provider.dart';

class RegistrationChart extends ConsumerWidget {
  const RegistrationChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(adminRegistrationChartProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Registrations',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Monthly sign-ups on Rozgar',
              style: context.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            chartAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: Text('Loading chart...')),
              ),
              error: (e, _) => SizedBox(
                height: 200,
                child: Center(child: Text('Chart error: $e')),
              ),
              data: (data) {
                final entries = data.entries.toList();
                final maxY = entries
                        .map((e) => e.value)
                        .fold<int>(0, (a, b) => a > b ? a : b)
                        .toDouble() +
                    1;

                return SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY < 2 ? 2 : maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
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
                            reservedSize: 28,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= entries.length) {
                                return const SizedBox.shrink();
                              }
                              final label = entries[i].key;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label.length >= 7
                                      ? label.substring(5)
                                      : label,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(entries.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: entries[i].value.toDouble(),
                              color: context.colorScheme.primary,
                              width: 18,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
