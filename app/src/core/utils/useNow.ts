import { useEffect, useState } from 'react';

/**
 * The wall clock, re-read every [intervalMs] while [active] — for countdowns.
 *
 * Inactive, it stops ticking and returns the last value, so a screen with
 * nothing counting down does not re-render once a second for no reason. On
 * reactivation that value can be stale for a frame, until the first tick;
 * countdowns built on it clamp to what they are counting.
 */
export function useNow(intervalMs: number, active = true): number {
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    if (!active) return;
    const tick = () => setNow(Date.now());
    const first = setTimeout(tick, 0);
    const id = setInterval(tick, intervalMs);
    return () => {
      clearTimeout(first);
      clearInterval(id);
    };
  }, [intervalMs, active]);

  return now;
}
