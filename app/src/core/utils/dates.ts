import { format } from 'date-fns';

/** The `intl` DateFormat patterns the Flutter build used, as date-fns formats. */
export const formatHms = (date: Date) => format(date, 'HH:mm:ss');
export const formatHm = (date: Date) => format(date, 'HH:mm');
export const formatMMMd = (date: Date) => format(date, 'MMM d');
export const formatMd = (date: Date) => format(date, 'M/d');
export const formatYMMMd = (date: Date) => format(date, 'MMM d, yyyy');
export const formatYMMMdHm = (date: Date) => format(date, 'MMM d, yyyy HH:mm');

/** `45s`, `12m`, `1h 05m` — how long a batch ran. */
export function formatDuration(ms: number): string {
  const totalSeconds = Math.floor(ms / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  if (minutes < 1) return `${totalSeconds}s`;
  if (minutes < 60) return `${minutes}m`;
  return `${Math.floor(minutes / 60)}h ${minutes % 60}m`;
}

/**
 * `0:45`, `12:05`, `1:02:09` — a countdown. Rounded up, so it shows the full
 * time at the start and reads `0:00` only once the time is actually up.
 */
export function formatCountdown(ms: number): string {
  const total = Math.max(0, Math.ceil(ms / 1000));
  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  const seconds = String(total % 60).padStart(2, '0');
  if (hours > 0) return `${hours}:${String(minutes).padStart(2, '0')}:${seconds}`;
  return `${minutes}:${seconds}`;
}

/** `45 s`, `2 min`, `1 min 30 s`, `1 h 15 min` — a set length of time, in words. */
export function formatSpan(totalSeconds: number): string {
  const total = Math.max(0, Math.round(totalSeconds));
  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  const seconds = total % 60;
  const parts: string[] = [];
  if (hours > 0) parts.push(`${hours} h`);
  if (minutes > 0) parts.push(`${minutes} min`);
  if (seconds > 0 || parts.length === 0) parts.push(`${seconds} s`);
  return parts.join(' ');
}
