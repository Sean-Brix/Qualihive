import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';

import { db } from '@/core/database/client';

import { DrizzleAuthRepository, type AuthRepository } from '../data/authRepository';
import { ADMIN_USERNAME, type Account } from '../domain/account';

const ACCOUNT_ID_KEY = 'qualihive.session.account_id';

export const authRepository: AuthRepository = new DrizzleAuthRepository(db);

interface SessionState {
  /** The signed-in admin, or null when nobody is. */
  account: Account | null;
  /** True until the stored session has been read back from disk. */
  loading: boolean;
  restore(): Promise<void>;
  signIn(username: string, password: string): Promise<void>;
  signOut(): Promise<void>;
  updateProfile(changes: { displayName?: string; farmName?: string; email?: string }): Promise<void>;
}

async function remember(accountId: number) {
  await AsyncStorage.setItem(ACCOUNT_ID_KEY, String(accountId));
}

/**
 * The session survives a restart because the account id is written to
 * AsyncStorage — only the id, never the password. Signing out clears it.
 */
export const useSessionStore = create<SessionState>((set, get) => ({
  account: null,
  loading: true,

  restore: async () => {
    try {
      const stored = await AsyncStorage.getItem(ACCOUNT_ID_KEY);
      const id = stored == null ? null : Number.parseInt(stored, 10);
      let account: Account | null = null;
      if (id != null && Number.isFinite(id)) {
        account = await authRepository.findById(id);
        // A session left over from an account other than admin (from before
        // sign-up was removed) no longer counts.
        if (account?.username !== ADMIN_USERNAME) {
          account = null;
          await AsyncStorage.removeItem(ACCOUNT_ID_KEY);
        }
      }
      set({ account, loading: false });
    } catch {
      set({ account: null, loading: false });
    }
  },

  signIn: async (username, password) => {
    const account = await authRepository.signIn(username, password);
    await remember(account.id);
    set({ account });
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
}));

export const useAccount = () => useSessionStore((s) => s.account);

/** Id of the signed-in account, for stamping onto batch records (§7). */
export const readCurrentAccountId = () => useSessionStore.getState().account?.id ?? null;
