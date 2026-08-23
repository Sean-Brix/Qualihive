import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../monitoring/application/monitoring_providers.dart';
import '../../monitoring/domain/alert.dart';
import '../../monitoring/presentation/widgets/quality_colors.dart';

/// Alerts, warnings and completion messages — specification §3 and §9.
///
/// These are in-app notifications: they are recorded whether or not the app is
/// open, and read here. The app does not post to the phone's system
/// notification tray, which would need a foreground service to keep the BLE
/// link alive in the background.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const String segment = 'notifications';
  static const String name = 'notifications';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final alerts = ref.watch(alertFeedProvider).value ?? const <Alert>[];
    final controller = ref.read(monitoringControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: <Widget>[
          if (alerts.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'read':
                    await controller.acknowledgeAllAlerts();
                  case 'clear':
                    await controller.clearAlerts();
                }
              },
              itemBuilder: (context) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'read',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.done_all),
                    title: Text('Mark all as read'),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'clear',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline),
                    title: Text('Clear all'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: alerts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.notifications_none,
                      size: 52,
                      color: scheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text('No notifications', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text(
                      'Out-of-range readings, sensor faults, disconnections '
                      'and completed batches show up here.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: alerts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return Dismissible(
                  key: ValueKey<int>(alert.id ?? index),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: scheme.errorContainer,
                    child: Icon(
                      Icons.delete_outline,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                  onDismissed: (_) {
                    if (alert.id != null) {
                      ref
                          .read(alertRepositoryProvider)
                          .delete(alert.id!)
                          .ignore();
                    }
                  },
                  child: _AlertTile(alert: alert),
                );
              },
            ),
    );
  }
}

class _AlertTile extends ConsumerWidget {
  const _AlertTile({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = alert.severity.color(scheme);

    return ListTile(
      onTap: alert.acknowledged || alert.id == null
          ? null
          : () => ref
              .read(monitoringControllerProvider.notifier)
              .acknowledgeAlert(alert.id!),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(alert.kind.icon, size: 19, color: color),
      ),
      title: Text(
        alert.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight:
              alert.acknowledged ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 2),
          Text(alert.body, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            <String>[
              DateFormat.yMMMd().add_Hm().format(alert.raisedAt),
              if (alert.batchCode != null) alert.batchCode!,
            ].join('  ·  '),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: alert.acknowledged
          ? null
          : Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
      isThreeLine: true,
    );
  }
}
