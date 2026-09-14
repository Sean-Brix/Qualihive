import { count, eq } from 'drizzle-orm';

import type { AppDatabase } from '@/core/database/client';
import { accounts, type AccountRow } from '@/core/database/schema';

import { AuthError, type Account } from '../domain/account';
import { hashPassword, verifyPassword } from './passwordHasher';

const USERNAME_PATTERN = /^[a-z0-9._]{3,24}$/;

export interface SignUpInput {
  username: string;
  password: string;
  displayName: string;
  farmName?: string | null;
  email?: string | null;
  now?: Date;
}

export interface AuthRepository {
  /** Creates a local account and returns it signed in. */
  signUp(input: SignUpInput): Promise<Account>;
  signIn(username: string, password: string, now?: Date): Promise<Account>;
  findById(id: number): Promise<Account | null>;
  /**
   * True when at least one account exists, which decides whether the app
   * opens on Sign in or on Sign up.
   */
  hasAnyAccount(): Promise<boolean>;
  updateProfile(
    account: Account,
    changes: { displayName?: string; farmName?: string; email?: string },
  ): Promise<Account>;
  changePassword(account: Account, currentPassword: string, newPassword: string): Promise<void>;
}

/**
 * At least 8 characters with a letter and a digit. Modest, but it is the
 * only barrier on an offline device and the beekeeper types it in a shed.
 */
export function isPasswordAcceptable(password: string): boolean {
  return password.length >= 8 && /[A-Za-z]/.test(password) && /[0-9]/.test(password);
}

const orNull = (value: string | null | undefined): string | null => {
  const trimmed = value?.trim();
  return trimmed == null || trimmed.length === 0 ? null : trimmed;
};

export function accountFromRow(row: AccountRow): Account {
  return {
    id: row.id,
    username: row.username,
    displayName: row.displayName,
    farmName: row.farmName,
    email: row.email,
    createdAt: row.createdAt,
    lastLoginAt: row.lastLoginAt,
  };
}

/**
 * Sign-up, sign-in and profile edits against the local accounts table.
 *
 * Every method throws [AuthError] on a rejected attempt, so the UI has one
 * thing to catch and one message to show.
 */
export class DrizzleAuthRepository implements AuthRepository {
  constructor(private readonly db: AppDatabase) {}

  private async findRowByUsername(username: string): Promise<AccountRow | null> {
    const [row] = await this.db
      .select()
      .from(accounts)
      .where(eq(accounts.username, username.toLowerCase()))
      .limit(1);
    return row ?? null;
  }

  private async findRowById(id: number): Promise<AccountRow | null> {
    const [row] = await this.db.select().from(accounts).where(eq(accounts.id, id)).limit(1);
    return row ?? null;
  }

  async signUp(input: SignUpInput): Promise<Account> {
    const handle = input.username.trim().toLowerCase();
    if (!USERNAME_PATTERN.test(handle)) throw new AuthError('invalidUsername');
    if (!isPasswordAcceptable(input.password)) throw new AuthError('weakPassword');
    if ((await this.findRowByUsername(handle)) != null) throw new AuthError('usernameTaken');

    const digest = await hashPassword(input.password);
    const createdAt = input.now ?? new Date();
    const trimmedName = input.displayName.trim();
    const name = trimmedName.length === 0 ? handle : trimmedName;

    const [inserted] = await this.db
      .insert(accounts)
      .values({
        username: handle,
        displayName: name,
        farmName: orNull(input.farmName),
        email: orNull(input.email),
        passwordHash: digest.hash,
        passwordSalt: digest.salt,
        hashIterations: digest.iterations,
        createdAt,
        lastLoginAt: createdAt,
      })
      .returning({ id: accounts.id });

    return {
      id: inserted.id,
      username: handle,
      displayName: name,
      farmName: orNull(input.farmName),
      email: orNull(input.email),
      createdAt,
      lastLoginAt: createdAt,
    };
  }

  async signIn(username: string, password: string, now: Date = new Date()): Promise<Account> {
    const row = await this.findRowByUsername(username.trim());
    if (row == null) throw new AuthError('unknownUser');

    const matches = await verifyPassword(password, {
      hash: row.passwordHash,
      salt: row.passwordSalt,
      iterations: row.hashIterations,
    });
    if (!matches) throw new AuthError('wrongPassword');

    await this.db.update(accounts).set({ lastLoginAt: now }).where(eq(accounts.id, row.id));
    return { ...accountFromRow(row), lastLoginAt: now };
  }

  async findById(id: number): Promise<Account | null> {
    const row = await this.findRowById(id);
    return row ? accountFromRow(row) : null;
  }

  async hasAnyAccount(): Promise<boolean> {
    const [row] = await this.db.select({ value: count() }).from(accounts);
    return (row?.value ?? 0) > 0;
  }

  async updateProfile(
    account: Account,
    changes: { displayName?: string; farmName?: string; email?: string },
  ): Promise<Account> {
    const updated: Account = {
      ...account,
      displayName: changes.displayName?.trim() ?? account.displayName,
      farmName: changes.farmName?.trim() ?? account.farmName,
      email: changes.email?.trim() ?? account.email,
    };

    await this.db
      .update(accounts)
      .set({
        displayName: updated.displayName,
        farmName: orNull(updated.farmName),
        email: orNull(updated.email),
      })
      .where(eq(accounts.id, account.id));

    return updated;
  }

  async changePassword(
    account: Account,
    currentPassword: string,
    newPassword: string,
  ): Promise<void> {
    const row = await this.findRowById(account.id);
    if (row == null) throw new AuthError('unknownUser');

    const matches = await verifyPassword(currentPassword, {
      hash: row.passwordHash,
      salt: row.passwordSalt,
      iterations: row.hashIterations,
    });
    if (!matches) throw new AuthError('wrongPassword');
    if (!isPasswordAcceptable(newPassword)) throw new AuthError('weakPassword');

    const digest = await hashPassword(newPassword);
    await this.db
      .update(accounts)
      .set({
        passwordHash: digest.hash,
        passwordSalt: digest.salt,
        hashIterations: digest.iterations,
      })
      .where(eq(accounts.id, account.id));
  }
}
