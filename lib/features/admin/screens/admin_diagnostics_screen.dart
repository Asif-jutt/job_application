import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/services/app_diagnostics_service.dart';
import '../../../core/utils/debug_log_store.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/rozgar_shell_body.dart';

final diagnosticsProvider = FutureProvider<List<DiagnosticItem>>((ref) {
  return AppDiagnosticsService(
    encryption: ref.watch(aesEncryptionProvider),
  ).collect();
});

/// Admin screen showing rubric implementation status + live debug logs.
class AdminDiagnosticsScreen extends ConsumerWidget {
  const AdminDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticsAsync = ref.watch(diagnosticsProvider);
    final logs = DebugLogStore.instance.entries;

    return RozgarShellBody(
      child: diagnosticsAsync.when(
      loading: () => const Center(child: Text('Running diagnostics...')),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        final grouped = <String, List<DiagnosticItem>>{};
        for (final item in items) {
          grouped.putIfAbsent(item.category, () => []).add(item);
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(diagnosticsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Rozgar System Diagnostics',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rubric implementation verification for semester project',
                style: context.textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              ...grouped.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...entry.value.map((item) => _DiagnosticRow(item: item)),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(
                'Live Debug Logs (${logs.length})',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (logs.isEmpty)
                const Text('No logs yet — use the app to generate activity.')
              else
                ...logs.take(20).map(
                      (log) => ListTile(
                        dense: true,
                        leading: _logIcon(log.level),
                        title: Text(
                          log.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        subtitle: Text(
                          '${log.level} · ${log.timestamp.toIso8601String().substring(11, 19)}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    ),
    );
  }

  Icon _logIcon(String level) {
    final icon = switch (level) {
      'ERROR' || 'SEVERE' => Icons.error_outline,
      'WARN' => Icons.warning_amber_outlined,
      'AUTH' => Icons.lock_outline,
      'NETWORK' => Icons.wifi_outlined,
      _ => Icons.info_outline,
    };
    return Icon(icon, size: 18);
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.item});
  final DiagnosticItem item;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.status) {
      DiagnosticStatus.pass => (Icons.check_circle, Colors.green),
      DiagnosticStatus.warn => (Icons.warning_amber, Colors.orange),
      DiagnosticStatus.fail => (Icons.cancel, Colors.red),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  item.detail,
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
