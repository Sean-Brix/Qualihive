/**
 * A beekeeper's account.
 *
 * Specification §2 lists "log in or sign up" among the expected activities,
 * and §12 settles the system as offline with no cloud. Accounts therefore
 * live only in the phone's SQLite database: signing up creates a local
 * record, and there is nothing to sync or recover from a server. That is a
 * deliberate limitation of an offline design, not an omission — a forgotten
 * password can only be reset from the device.
 */
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

/**
 * Why a sign-in or sign-up attempt failed.
 *
 * `unknownUser` and `wrongPassword` are separate internally but the UI shows
 * one message for both, so a stranger cannot use the login form to discover
 * which accounts exist on the device.
 */
export type AuthFailure =
  | 'unknownUser'
  | 'wrongPassword'
  | 'usernameTaken'
  | 'weakPassword'
  | 'invalidUsername';

export function authFailureMessage(failure: AuthFailure): string {
  switch (failure) {
    case 'unknownUser':
    case 'wrongPassword':
      return 'Incorrect username or password.';
    case 'usernameTaken':
      return 'That username already exists on this device.';
    case 'weakPassword':
      return 'Use at least 8 characters, including a letter and a number.';
    case 'invalidUsername':
      return 'Usernames are 3–24 characters: letters, numbers, dots or underscores.';
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
