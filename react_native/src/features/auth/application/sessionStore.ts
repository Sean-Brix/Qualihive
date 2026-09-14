import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';

import { db } from '@/core/database/client';

import { DrizzleAuthRepository, type AuthRepository, type SignUpInput } from '../data/authRepository';
import { AuthError, type Account } from '../domain/account';

const ACCOUNT_ID_KEY = 'qualihive.session.account_id';

export const authRepository: AuthRepository = new DrizzleAuthRepository(db);

interface SessionState {
  /** The signed-in beekeeper, or null when nobody is. */
  account: Account | null;
  /** True until the stored session has been read back from disk. */
  loading: boolean;
  /**
   * Whether any account exists yet, which decides whether the app opens on
   * Sign in or on Create account. Null until known.
   */
  hasAnyAccount: boolean | null;
  restore(): Promise<void>;
  refreshHasAnyAccount(): Promise<void>;
  signIn(username: string, password: string): Promise<void>;
  signUp(input: SignUpInput): Promise<void>;
  signOut(): Promise<void>;
  updateProfile(changes: { displayName?: string; farmName?: string; email?: string }): Promise<void>;
  changePassword(currentPassword: string, newPassword: string): Promise<void>;
}

async function remember(accountId: number) {
  await AsyncStorage.setItem(ACCOUNT_ID_KEY, String(accountId));
}

/**
 * The session survives a restart because the account id is written to
 * AsyncStorage — only the id, never the password or its hash. Signing out
 * clears it.
 */
export const useSessionStore = create<SessionState>((set, get) => ({
  account: null,
  loading: true,
  hasAnyAccount: null,

  restore: async () => {
    try {
      const stored = await AsyncStorage.getItem(ACCOUNT_ID_KEY);
      const id = stored == null ? null : Number.parseInt(stored, 10);
      let account: Account | null = null;
      if (id != null && Number.isFinite(id)) {
        account = await authRepository.findById(id);
        // The account was deleted underneath a stale session.
        if (account == null) await AsyncStorage.removeItem(ACCOUNT_ID_KEY);
      }
      const hasAnyAccount = await authRepository.hasAnyAccount();
      set({ account, loading: false, hasAnyAccount });
    } catch {
      set({ account: null, loading: false, hasAnyAccount: false });
    }
  },

  refreshHasAnyAccount: async () => {
    set({ hasAnyAccount: await authRepository.hasAnyAccount() });
  },

  signIn: async (username, password) => {
    const account = await authRepository.signIn(username, password);
    await remember(account.id);
    set({ account, hasAnyAccount: true });
  },

  signUp: async (input) => {
    const account = await authRepository.signUp(input);
    await remember(account.id);
    set({ account, hasAnyAccount: true });
  },

  signOut: async () => {
    await AsyncStorage.removeItem(ACCOUNT_ID_KEY);
    set({ account: null });
  },

  updateProfile: async (changes) => {
    const current = get().account;
    if (current == null) return;
    const account = await authRepository.updateProfile(current, changes);
    set({ account });
  },

  changePassword: async (currentPassword, newPassword) => {
    const current = get().account;
    if (current == null) throw new AuthError('unknownUser');
    await authRepository.changePassword(current, currentPassword, newPassword);
  },
}));

export const useAccount = () => useSessionStore((s) => s.account);

/** Id of the signed-in account, for stamping onto batch records (§7). */
export const readCurrentAccountId = () => useSessionStore.getState().account?.id ?? null;
