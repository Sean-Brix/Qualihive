import { useState } from 'react';
import { FlatList, Pressable, StyleSheet, View } from 'react-native';
import Animated, { FadeOut, LinearTransition } from 'react-native-reanimated';

import { IconButton } from '@/core/components/Button';
import { Icon } from '@/core/components/Icon';
import { Divider, ListTile } from '@/core/components/ListTile';
import { Message } from '@/core/components/Misc';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { OptionsSheet } from '@/core/components/Sheet';
import { Text } from '@/core/components/Text';
import { alpha } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';
import { formatYMMMdHm } from '@/core/utils/dates';
import { useMonitoringStore } from '@/features/monitoring/application/monitoringStore';
import { useAlertFeed } from '@/features/monitoring/application/queries';
import type { Alert } from '@/features/monitoring/domain/alert';
import { alertKindIcon, severityColor } from '@/features/monitoring/presentation/widgets/qualityColors';

/**
 * Alerts, warnings and completion messages — specification §3 and §9.
 *
 * These are in-app notifications: they are recorded whether or not the app is
 * open, and read here. The app does not post to the phone's system
 * notification tray, which would need a foreground service to keep the BLE
 * link alive in the background.
 */
export function NotificationsScreen() {
  const { data: alerts } = useAlertFeed();
  const acknowledgeAll = useMonitoringStore((s) => s.acknowledgeAllAlerts);
  const clearAlerts = useMonitoringStore((s) => s.clearAlerts);
  const bottom = useBottomPadding(24);
  const [menu, setMenu] = useState(false);

  return (
    <Screen>
      <AppBar
        title="Notifications"
        back
        actions={
          alerts.length > 0 ? (
            <IconButton icon="more-vert" accessibilityLabel="More options" onPress={() => setMenu(true)} />
          ) : undefined
        }
      />
      <OptionsSheet
        visible={menu}
        onClose={() => setMenu(false)}
        onSelect={(key) => {
          if (key === 'read') void acknowledgeAll();
          if (key === 'clear') void clearAlerts();
        }}
        options={[
          { key: 'read', label: 'Mark all as read', icon: 'done-all' },
          { key: 'clear', label: 'Clear all', icon: 'delete-outline' },
        ]}
      />
      {alerts.length === 0 ? (
        <Message
          icon="notifications-none"
          title="No notifications"
          body="Out-of-range readings, sensor faults, disconnections and completed batches show up here."
        />
      ) : (
        <FlatList
          data={alerts}
          keyExtractor={(alert, index) => String(alert.id ?? index)}
          contentContainerStyle={{ paddingVertical: 8, paddingBottom: bottom }}
          ItemSeparatorComponent={() => <Divider />}
          renderItem={({ item }) => <AlertTile alert={item} />}
        />
      )}
    </Screen>
  );
}

function AlertTile({ alert }: { alert: Alert }) {
  const { scheme } = useTheme();
  const acknowledge = useMonitoringStore((s) => s.acknowledgeAlert);
  const deleteAlert = useMonitoringStore((s) => s.deleteAlert);
  const color = severityColor(alert.severity, scheme);

  return (
    <Animated.View exiting={FadeOut} layout={LinearTransition}>
      <ListTile
        minHeight={80}
        onPress={alert.acknowledged || alert.id == null ? undefined : () => void acknowledge(alert.id!)}
        leading={
          <View style={[styles.iconBox, { backgroundColor: alpha(color, 0.14) }]}>
            <Icon name={alertKindIcon(alert.kind)} size={19} color={color} />
          </View>
        }
        title={
          <Text variant="bodyMedium" weight={alert.acknowledged ? '400' : '600'}>
            {alert.title}
          </Text>
        }
        subtitle={
          <View style={{ marginTop: 2 }}>
            <Text variant="bodySmall">{alert.body}</Text>
            <Text variant="labelSmall" color={scheme.onSurfaceVariant} style={{ marginTop: 4 }}>
              {[formatYMMMdHm(alert.raisedAt), alert.batchCode].filter(Boolean).join('  ·  ')}
            </Text>
          </View>
        }
        trailing={
          <View style={styles.trailing}>
            {!alert.acknowledged && <View style={[styles.unread, { backgroundColor: color }]} />}
            {alert.id != null && (
              <Pressable
                onPress={() => void deleteAlert(alert.id!)}
                hitSlop={8}
                accessibilityLabel="Delete notification"
                style={({ pressed }) => ({ opacity: pressed ? 0.5 : 1 })}
              >
                <Icon name="close" size={18} color={scheme.outline} />
              </Pressable>
            )}
          </View>
        }
      />
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  iconBox: { width: 38, height: 38, borderRadius: 11, alignItems: 'center', justifyContent: 'center' },
  trailing: { alignItems: 'center', gap: 10 },
  unread: { width: 9, height: 9, borderRadius: 4.5 },
});
