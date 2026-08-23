import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/monitoring_providers.dart';
import '../data/transport/sensor_transport.dart';
import 'widgets/connection_pill.dart';

/// Pick a data source, scan, and connect.
class DeviceScreen extends ConsumerWidget {
  const DeviceScreen({super.key});

  /// Nested under More, so a back gesture returns there.
  static const String segment = 'device';
  static const String name = 'device';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(transportStatusProvider).value ??
        const TransportStatus.disconnected();
    final devices =
        ref.watch(discoveredDevicesProvider).value ?? const <DiscoveredDevice>[];
    final mode = ref.watch(transportModeControllerProvider);
    final controller = ref.read(monitoringControllerProvider.notifier);

    ref.listen(monitoringControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('$error')));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Machine connection'),
        actions: <Widget>[
          ConnectionPill(status: status),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Text('Source', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<TransportKind>(
            segments: TransportKind.values
                .map(
                  (kind) => ButtonSegment<TransportKind>(
                    value: kind,
                    label: Text(kind.label),
                    icon: Icon(
                      kind == TransportKind.ble
                          ? Icons.bluetooth
                          : Icons.science_outlined,
                    ),
                  ),
                )
                .toList(growable: false),
            selected: <TransportKind>{mode},
            onSelectionChanged: (selection) => ref
                .read(transportModeControllerProvider.notifier)
                .select(selection.first),
          ),
          if (mode == TransportKind.simulator)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Generates readings locally. Use this on an emulator, which '
                'has no Bluetooth radio.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          const SizedBox(height: 20),
          if (status.isConnected)
            _ConnectedCard(
              status: status,
              onDisconnect: controller.disconnect,
            )
          else
            FilledButton.icon(
              onPressed: status.state == TransportState.scanning
                  ? controller.stopScan
                  : controller.scan,
              icon: Icon(
                status.state == TransportState.scanning
                    ? Icons.stop
                    : Icons.bluetooth_searching,
              ),
              label: Text(
                status.state == TransportState.scanning
                    ? 'Stop scanning'
                    : 'Scan for devices',
              ),
            ),
          if (status.state == TransportState.unavailable ||
              status.state == TransportState.error)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                status.message ?? status.label,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          Text('Found', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          if (devices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                status.state == TransportState.scanning
                    ? 'Scanning…'
                    : 'No devices yet. Run a scan.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...devices.map(
              (device) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.memory),
                title: Text(device.displayName),
                subtitle: Text(device.id),
                trailing: device.rssi == 0
                    ? null
                    : Text('${device.rssi} dBm'),
                onTap: status.isBusy
                    ? null
                    : () => controller.connect(device),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({required this.status, required this.onDisconnect});

  final TransportStatus status;
  final Future<void> Function() onDisconnect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  status.device?.displayName ?? 'Connected',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (status.device != null)
                  Text(
                    status.device!.id,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onDisconnect,
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
