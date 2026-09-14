/**
 * A small seedable pseudo-random source, with the same surface as Dart's
 * `Random`, so the simulator and the sample-data seeder are reproducible.
 *
 * mulberry32 — good enough distribution for demo data, tiny, and deterministic
 * for a given seed across platforms.
 */
export class SeededRandom {
  private state: number;

  constructor(seed: number) {
    this.state = seed >>> 0;
  }

  /** Uniform in [0, 1). */
  nextDouble(): number {
    this.state = (this.state + 0x6d2b79f5) >>> 0;
    let t = this.state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }

  /** Uniform integer in [0, max). */
  nextInt(max: number): number {
    return Math.floor(this.nextDouble() * max);
  }
}

export interface RandomSource {
  nextDouble(): number;
  nextInt(max: number): number;
}
