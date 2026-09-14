import { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';

import { Button } from '@/core/components/Button';
import { Icon } from '@/core/components/Icon';
import { Divider, ListTile } from '@/core/components/ListTile';
import { Loading } from '@/core/components/Misc';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { Sheet } from '@/core/components/Sheet';
import { Text } from '@/core/components/Text';
import { TextField } from '@/core/components/TextField';
import { showToast } from '@/core/components/Toast';
import { useTheme } from '@/core/theme/useTheme';
import { formatYMMMd } from '@/core/utils/dates';

import { useAccount, useSessionStore } from '../application/sessionStore';
import { AuthError, accountInitials, type Account } from '../domain/account';

/** Account details and password change — specification §9. */
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
  const changePassword = useSessionStore((s) => s.changePassword);
  const bottom = useBottomPadding(40);

  // Seeded once from the account; a rebuild does not overwrite what is being typed.
  const [displayName, setDisplayName] = useState(account.displayName);
  const [farmName, setFarmName] = useState(account.farmName ?? '');
  const [email, setEmail] = useState(account.email ?? '');
  const [dirty, setDirty] = useState(false);
  const [passwordSheet, setPasswordSheet] = useState(false);

  const edit = (setter: (value: string) => void) => (value: string) => {
    setter(value);
    setDirty(true);
  };

  const save = async () => {
    await updateProfile({ displayName, farmName, email });
    setDirty(false);
    showToast('Profile updated.');
  };

  const submitPassword = async (current: string, next: string) => {
    setPasswordSheet(false);
    try {
      await changePassword(current, next);
      showToast('Password changed.');
    } catch (error) {
      showToast(error instanceof AuthError ? error.message : String(error));
    }
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
        <View style={{ height: 28 }} />
        <Divider />
        <View style={{ height: 12 }} />
        <ListTile
          paddingHorizontal={0}
          leading={<Icon name="lock-outline" size={24} color={scheme.onSurfaceVariant} />}
          title="Change password"
          trailing={<Icon name="chevron-right" size={24} color={scheme.onSurfaceVariant} />}
          onPress={() => setPasswordSheet(true)}
        />
      </ScrollView>
      <PasswordSheet visible={passwordSheet} onClose={() => setPasswordSheet(false)} onSubmit={submitPassword} />
    </Screen>
  );
}

function PasswordSheet({
  visible,
  onClose,
  onSubmit,
}: {
  visible: boolean;
  onClose: () => void;
  onSubmit: (current: string, next: string) => void;
}) {
  const [current, setCurrent] = useState('');
  const [next, setNext] = useState('');
  const [confirm, setConfirm] = useState('');
  const [errors, setErrors] = useState<Record<string, string | null>>({});

  const submit = () => {
    const nextErrors = {
      current: current.length === 0 ? 'Required' : null,
      next: next.length === 0 ? 'Required' : null,
      confirm: confirm === next ? null : 'The passwords do not match',
    };
    setErrors(nextErrors);
    if (Object.values(nextErrors).some((e) => e != null)) return;
    onSubmit(current, next);
    setCurrent('');
    setNext('');
    setConfirm('');
  };

  return (
    <Sheet visible={visible} onClose={onClose} scroll>
      <View style={styles.sheet}>
        <Text variant="titleLarge" weight="700">
          Change password
        </Text>
        <View style={{ height: 20 }} />
        <TextField label="Current password" value={current} onChangeText={setCurrent} secureTextEntry errorText={errors.current} />
        <View style={{ height: 14 }} />
        <TextField
          label="New password"
          value={next}
          onChangeText={setNext}
          secureTextEntry
          helperText="At least 8 characters, with a letter and a number"
          errorText={errors.next}
        />
        <View style={{ height: 14 }} />
        <TextField label="Confirm new password" value={confirm} onChangeText={setConfirm} secureTextEntry errorText={errors.confirm} />
        <View style={{ height: 22 }} />
        <Button label="Change password" onPress={submit} />
      </View>
    </Sheet>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 20, paddingTop: 20 },
  hero: { alignItems: 'center' },
  avatar: { width: 72, height: 72, borderRadius: 36, alignItems: 'center', justifyContent: 'center' },
  sheet: { paddingHorizontal: 20, paddingBottom: 8 },
});
