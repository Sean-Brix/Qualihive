import { Image } from 'expo-image';
import { StyleSheet, View } from 'react-native';

import { useTheme } from '../theme/useTheme';
import { Text } from './Text';

const ICON = require('../../../assets/branding/qualihive_app_icon.png');

/**
 * The production Qualihive mark.
 *
 * The generated symbol combines a honeycomb chamber, a droplet, a filter gate
 * and a subtle Q silhouette. Keeping it behind this component gives every
 * call site the same clipping and image-quality settings.
 */
export function QualihiveLogo({ size = 32 }: { size?: number }) {
  return (
    <Image
      source={ICON}
      accessibilityLabel="Qualihive"
      contentFit="cover"
      style={{ width: size, height: size, borderRadius: size * 0.28 }}
    />
  );
}

/** Logo plus wordmark, for app bars and branded empty states. */
export function QualihiveWordmark({ size = 26 }: { size?: number }) {
  const { scheme } = useTheme();
  return (
    <View style={[styles.row, { gap: size * 0.35 }]} accessibilityLabel="Qualihive">
      <QualihiveLogo size={size} />
      <Text variant="titleLarge" weight="800" letterSpacing={-0.65}>
        Quali
        <Text variant="titleLarge" weight="800" letterSpacing={-0.65} color={scheme.secondary}>
          hive
        </Text>
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center' },
});
