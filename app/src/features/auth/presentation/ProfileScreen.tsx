import { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';

import { Button } from '@/core/components/Button';
import { Loading } from '@/core/components/Misc';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { Text } from '@/core/components/Text';
import { TextField } from '@/core/components/TextField';
import { showToast } from '@/core/components/Toast';
import { useTheme } from '@/core/theme/useTheme';
import { formatYMMMd } from '@/core/utils/dates';

import { useAccount, useSessionStore } from '../application/sessionStore';
import { accountInitials, type Account } from '../domain/account';

/** Account details — specification §9. */
export function ProfileScreen() {
  const account = useAccount();
  if (account == null) {
    return (
      <Screen>
        <AppBar title="Profile" back />
        <Loading />
      </Screen>
    );
  }
  return <ProfileBody key={account.id} account={account} />;
}

function ProfileBody({ account }: { account: Account }) {
  const { scheme } = useTheme();
  const updateProfile = useSessionStore((s) => s.updateProfile);
  const bottom = useBottomPadding(40);

  // Seeded once from the account; a rebuild does not overwrite what is being typed.
  const [displayName, setDisplayName] = useState(account.displayName);
  const [farmName, setFarmName] = useState(account.farmName ?? '');
  const [email, setEmail] = useState(account.email ?? '');
  const [dirty, setDirty] = useState(false);

  const edit = (setter: (value: string) => void) => (value: string) => {
    setter(value);
    setDirty(true);
  };

  const save = async () => {
    await updateProfile({ displayName, farmName, email });
    setDirty(false);
    showToast('Profile updated.');
  };

  return (
    <Screen>
      <AppBar title="Profile" back />
      <ScrollView contentContainerStyle={[styles.content, { paddingBottom: bottom }]} keyboardShouldPersistTaps="handled">
        <View style={styles.hero}>
          <View style={[styles.avatar, { backgroundColor: scheme.primaryContainer }]}>
            <Text variant="headlineSmall" weight="700" color={scheme.onPrimaryContainer}>
              {accountInitials(account)}
            </Text>
          </View>
          <Text variant="bodyMedium" style={{ marginTop: 12 }}>
            @{account.username}
          </Text>
          <Text variant="labelSmall" color={scheme.onSurfaceVariant}>
            Joined {formatYMMMd(account.createdAt)}
          </Text>
        </View>
        <View style={{ height: 28 }} />
        <TextField label="Name" value={displayName} onChangeText={edit(setDisplayName)} autoCapitalize="words" />
        <View style={{ height: 14 }} />
        <TextField label="Farm name" value={farmName} onChangeText={edit(setFarmName)} autoCapitalize="words" />
        <View style={{ height: 14 }} />
        <TextField
          label="Email (optional)"
          value={email}
          onChangeText={edit(setEmail)}
          keyboardType="email-address"
          autoCapitalize="none"
          helperText="Stored on this device only; nothing is sent to it"
        />
        <View style={{ height: 20 }} />
        <Button label="Save changes" disabled={!dirty} onPress={() => void save()} />
      </ScrollView>
    </Screen>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 20, paddingTop: 20 },
  hero: { alignItems: 'center' },
  avatar: { width: 72, height: 72, borderRadius: 36, alignItems: 'center', justifyContent: 'center' },
});
