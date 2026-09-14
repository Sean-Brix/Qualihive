import { Tabs } from 'expo-router';
import type { ComponentProps } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { Badge } from '@/core/components/Button';
import { Icon, type IconName } from '@/core/components/Icon';
import { Text } from '@/core/components/Text';
import { alpha } from '@/core/theme/theme';
import { useTheme } from '@/core/theme/useTheme';
import { useUnreadAlertCount } from '@/features/monitoring/application/queries';

type TabBarProps = Parameters<NonNullable<ComponentProps<typeof Tabs>['tabBar']>>[0];

/**
 * The five tabs of specification §10. Each keeps its own navigation stack
 * and scroll position when you switch between them.
 */
const TABS: { name: string; label: string; icon: IconName }[] = [
  { name: 'index', label: 'Home', icon: 'home' },
  { name: 'live', label: 'Live', icon: 'monitor-heart' },
  { name: 'statistics', label: 'Statistics', icon: 'insights' },
  { name: 'history', label: 'History', icon: 'history' },
  { name: 'more', label: 'More', icon: 'more-horiz' },
];

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{ headerShown: false, lazy: true }}
      tabBar={(props) => <MaterialTabBar {...props} />}
      backBehavior="initialRoute"
    >
      {TABS.map((tab) => (
        <Tabs.Screen key={tab.name} name={tab.name} options={{ title: tab.label }} />
      ))}
    </Tabs>
  );
}

/** A Material 3 navigation bar: pill indicator behind the icon, label always shown. */
function MaterialTabBar({ state, navigation }: TabBarProps) {
  const { scheme } = useTheme();
  const insets = useSafeAreaInsets();
  const unread = useUnreadAlertCount();

  return (
    <View
      style={[
        styles.bar,
        {
          backgroundColor: alpha(scheme.card, 0.98),
          borderTopColor: alpha(scheme.outlineVariant, 0.6),
          paddingBottom: insets.bottom,
          height: 74 + insets.bottom,
        },
      ]}
    >
      {state.routes.map((route, index) => {
        const tab = TABS.find((t) => t.name === route.name);
        if (!tab) return null;
        const selected = state.index === index;
        const badge = tab.name === 'more' ? unread : 0;

        const onPress = () => {
          const event = navigation.emit({ type: 'tabPress', target: route.key, canPreventDefault: true });
          if (selected) {
            // Tapping the current tab returns it to its root.
            navigation.emit({ type: 'tabLongPress', target: route.key });
            navigation.navigate(route.name, { screen: 'index' });
          } else if (!event.defaultPrevented) {
            navigation.navigate(route.name);
          }
        };

        return (
          <Pressable
            key={route.key}
            onPress={onPress}
            accessibilityRole="tab"
            accessibilityState={{ selected }}
            accessibilityLabel={tab.label}
            style={styles.tab}
          >
            <View style={[styles.indicator, selected && { backgroundColor: scheme.secondaryContainer }]}>
              <Icon
                name={tab.icon}
                size={selected ? 24 : 22}
                color={selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant}
              />
              {badge > 0 && <Badge count={badge} />}
            </View>
            <Text
              variant="labelSmall"
              weight={selected ? '800' : '600'}
              color={selected ? scheme.primary : scheme.onSurfaceVariant}
              style={{ marginTop: 4 }}
            >
              {tab.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: 'row',
    borderTopWidth: StyleSheet.hairlineWidth,
    paddingTop: 10,
  },
  tab: { flex: 1, alignItems: 'center', justifyContent: 'flex-start' },
  indicator: {
    width: 64,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
