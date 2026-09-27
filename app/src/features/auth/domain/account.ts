/**
 * The operator's account.
 *
 * The app has exactly one account with fixed credentials — there is no sign
 * up and no password change. Its row lives in the phone's SQLite database so
 * batches can be stamped with who ran them and the profile can be edited.
 */
export const ADMIN_USERNAME = 'admin';
export const ADMIN_PASSWORD = '123456';


export interface Account {
  readonly id: number;
  /** Lower-cased login handle. Unique across the device. */
  readonly username: string;
  readonly displayName: string;
  readonly farmName?: string | null;
  readonly email?: string | null;
  readonly createdAt: Date;
  readonly lastLoginAt?: Date | null;
}

/** Initials for the avatar, e.g. `HK` for "Honey Ko". */
export function accountInitials(account: Account): string {
  const parts = account.displayName
    .trim()
    .split(/\s+/)
    .filter((part) => part.length > 0);
  if (parts.length === 0) {
    return account.username.length === 0 ? '?' : account.username[0].toUpperCase();
  }
  if (parts.length === 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

/** Why a sign-in attempt failed. */
export type AuthFailure = 'wrongCredentials';

export function authFailureMessage(failure: AuthFailure): string {
  switch (failure) {
    case 'wrongCredentials':
      return 'Incorrect username or password.';
  }
}

/** Raised by the auth repository so the UI can show [authFailureMessage]. */
export class AuthError extends Error {
  readonly failure: AuthFailure;

  constructor(failure: AuthFailure) {
    super(authFailureMessage(failure));
    this.name = 'AuthError';
    this.failure = failure;
  }
}
