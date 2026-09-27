import { eq } from 'drizzle-orm';

import type { AppDatabase } from '@/core/database/client';
import { accounts, type AccountRow } from '@/core/database/schema';

import { ADMIN_PASSWORD, ADMIN_USERNAME, AuthError, type Account } from '../domain/account';
import { hashPassword } from './passwordHasher';

export interface AuthRepository {
  /** Checks the fixed admin credentials and returns the admin account. */
  signIn(username: string, password: string, now?: Date): Promise<Account>;
  findById(id: number): Promise<Account | null>;
  updateProfile(
    account: Account,
    changes: { displayName?: string; farmName?: string; email?: string },
  ): Promise<Account>;
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
 * Sign-in and profile edits for the single admin account.
 *
 * The credentials are fixed in code; the admin row is created on the first
 * successful sign-in so batches have an account id to be stamped with.
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

  private async createAdminRow(now: Date): Promise<AccountRow> {
    const digest = await hashPassword(ADMIN_PASSWORD);
    const [row] = await this.db
      .insert(accounts)
      .values({
        username: ADMIN_USERNAME,
        displayName: 'Admin',
        passwordHash: digest.hash,
        passwordSalt: digest.salt,
        hashIterations: digest.iterations,
        createdAt: now,
        lastLoginAt: now,
      })
      .returning();
    return row;
  }

  async signIn(username: string, password: string, now: Date = new Date()): Promise<Account> {
    if (username.trim().toLowerCase() !== ADMIN_USERNAME || password !== ADMIN_PASSWORD) {
      throw new AuthError('wrongCredentials');
    }

    const row = (await this.findRowByUsername(ADMIN_USERNAME)) ?? (await this.createAdminRow(now));
    await this.db.update(accounts).set({ lastLoginAt: now }).where(eq(accounts.id, row.id));
    return { ...accountFromRow(row), lastLoginAt: now };
  }

  async findById(id: number): Promise<Account | null> {
    const row = await this.findRowById(id);
    return row ? accountFromRow(row) : null;
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
}
