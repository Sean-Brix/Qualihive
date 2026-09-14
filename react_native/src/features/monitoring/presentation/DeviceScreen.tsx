import { useEffect } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';

import { Button } from '@/core/components/Button';
import { Segmented } from '@/core/components/Chips';
import { Icon } from '@/core/components/Icon';
import { ListTile } from '@/core/components/ListTile';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { Text } from '@/core/components/Text';
import { showToast } from '@/core/components/Toast';
import { radii } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';

import {
  TRANSPORT_KINDS,
  transportKindLabel,
  useMonitoringStore,
  type TransportKind,
} from '../application/monitoringStore';
import {
  deviceDisplayName,
  isBusy,
  isConnected,
  transportLabel,
  type TransportStatus,
} from '../data/transport/sensorTransport';
import { ConnectionPill } from './widgets/ConnectionPill';

/** Pick a data source, scan, and connect. */
export function DeviceScreen() {
  const { scheme } = useTheme();
  const status = useMonitoringStore((s) => s.status);
  const devices = useMonitoringStore((s) => s.discovered);
  const mode = useMonitoringStore((s) => s.transportKind);
  const error = useMonitoringStore((s) => s.error);
  const clearError = useMonitoringStore((s) => s.clearError);
  const selectTransport = useMonitoringStore((s) => s.selectTransport);
  const scan = useMonitoringStore((s) => s.scan);
  const stopScan = useMonitoringStore((s) => s.stopScan);
  const connect = useMonitoringStore((s) => s.connect);
  const disconnect = useMonitoringStore((s) => s.disconnect);
  const bottom = useBottomPadding(32);

  useEffect(() => {
    if (error != null) {
      showToast(error);
      clearError();
    }
  }, [error, clearError]);

  const scanning = status.state === 'scanning';

  return (
    <Screen>
      <AppBar title="Machine connection" back actions={<ConnectionPill status={status} />} />
      <ScrollView contentContainerStyle={[styles.content, { paddingBottom: bottom }]}>
        <Text variant="titleSmall" weight="600">
          Source
        </Text>
        <View style={{ height: 8 }} />
        <Segmented<TransportKind>
          options={TRANSPORT_KINDS.map((kind) => ({
            value: kind,
            label: transportKindLabel(kind),
            icon: kind === 'ble' ? 'bluetooth' : 'science',
          }))}
          value={mode}
          onChange={selectTransport}
        />
        {mode === 'simulator' && (
          <Text variant="bodySmall" style={{ marginTop: 8 }}>
            Generates readings locally. Use this on an emulator, which has no Bluetooth radio.
          </Text>
        )}
        <View style={{ height: 20 }} />

        {isConnected(status) ? (
          <ConnectedCard status={status} onDisconnect={() => void disconnect()} />
        ) : (
          <Button
            label={scanning ? 'Stop scanning' : 'Scan for devices'}
            icon={scanning ? 'stop' : 'bluetooth-searching'}
            onPress={() => void (scanning ? stopScan() : scan())}
          />
        )}
        {(status.state === 'unavailable' || status.state === 'error') && (
          <Text variant="bodyMedium" color={scheme.error} style={{ marginTop: 12 }}>
            {status.message ?? transportLabel(status)}
          </Text>
        )}

        <View style={{ height: 24 }} />
        <Text variant="titleSmall" weight="600">
          Found
        </Text>
        <View style={{ height: 4 }} />
        {devices.length === 0 ? (
          <Text variant="bodyMedium" color={scheme.onSurfaceVariant} style={{ paddingVertical: 24 }}>
            {scanning ? 'Scanning…' : 'No devices yet. Run a scan.'}
          </Text>
        ) : (
          devices.map((device) => (
            <ListTile
              key={device.id}
              paddingHorizontal={0}
              leading={<Icon name="memory" size={24} color={scheme.onSurfaceVariant} />}
              title={deviceDisplayName(device)}
              subtitle={device.id}
              trailing={
                device.rssi === 0 ? undefined : (
                  <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
                    {device.rssi} dBm
                  </Text>
                )
              }
              disabled={isBusy(status)}
              onPress={() => void connect(device)}
            />
          ))
        )}
      </ScrollView>
    </Screen>
  );
}

function ConnectedCard({ status, onDisconnect }: { status: TransportStatus; onDisconnect: () => void }) {
  const { scheme } = useTheme();
  return (
    <View style={[styles.connected, { backgroundColor: scheme.surfaceContainerHighest }]}>
      <View style={{ flex: 1 }}>
        <Text variant="titleMedium">
          {status.device ? deviceDisplayName(status.device) : 'Connected'}
        </Text>
        {status.device && (
          <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
            {status.device.id}
          </Text>
        )}
      </View>
      <Button variant="outlined" compact label="Disconnect" onPress={onDisconnect} />
    </View>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 16, paddingTop: 8 },
  connected: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    padding: 16,
    borderRadius: radii.md,
  },
});
