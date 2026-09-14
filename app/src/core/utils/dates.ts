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
