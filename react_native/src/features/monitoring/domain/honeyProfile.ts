import type { RandomSource } from '@/core/utils/random';

/**
 * What the machine got wrong, or what arrived wrong, on one run.
 *
 * Each value maps onto a different path through the assessment of §8, so a
 * demo that cycles through them exercises every verdict and every
 * recommendation the app can produce.
 */
export type HoneyTrouble =
  /** A sound lot: every parameter sits inside its reference range. */
  | 'none'
  /**
   * Harvested before the bees capped the pots, or stored in humid air.
   * Moisture runs above the accepted band — the fermentation risk §12 warns
   * about, and something filtration cannot fix.
   */
  | 'wetLot'
  /**
   * The heating jacket overshot. Temperature crosses the process limit while
   * the honey itself is fine.
   */
  | 'overheated'
  /**
   * Heavy in wax, propolis and pollen. Two filtration passes do not get the
   * clarity down to the accepted band, so another pass is worth recommending.
   */
  | 'cloudy';

export const HONEY_TROUBLES: readonly HoneyTrouble[] = ['none', 'wetLot', 'overheated', 'cloudy'];

/**
 * The properties one lot of honey has before the machine touches it.
 *
 * pH, moisture, conductivity and colour are characteristics of the honey
 * itself, not of the filtration run: across a single batch they move only as
 * far as sensor noise takes them. Turbidity is the exception, and the reason
 * the machine exists: it is the one parameter filtration changes. A profile
 * therefore carries both the clarity the lot arrives with and the clarity it
 * can be filtered down to, and the run interpolates between them.
 *
 * The distributions are centred inside the reference ranges the app grades
 * against, which come from the physico-chemical survey of *Tetragonula biroi*
 * honey the project is built on.
 */
export interface HoneyProfile {
  /** Acidity of the lot. */
  readonly ph: number;
  /** Water content, in per cent. */
  readonly moisture: number;
  /** Conductivity in mS/cm. */
  readonly electricalConductivity: number;
  /** Colour on the Pfund scale, in mm. */
  readonly colorPfund: number;
  /** Clarity as drawn from the tank, in NTU. */
  readonly rawTurbidity: number;
  /** Clarity the two filtration stages can reach, in NTU. */
  readonly filteredTurbidity: number;
  /** Room temperature at the start of the run, in °C. */
  readonly ambientC: number;
  /** Temperature the heating jacket settles at while honey is moving, in °C. */
  readonly workingC: number;
  /** How much honey the run puts through, in litres. */
  readonly volumeLitres: number;
  readonly trouble: HoneyTrouble;
}

/**
 * Honey is roughly 1.42 times as dense as water, which is what turns a
 * flow rate in litres per minute into a load-cell reading in kilograms.
 */
export const DENSITY_KG_PER_LITRE = 1.42;

/** What the load cell should read once the run finishes. */
export const yieldKg = (profile: HoneyProfile) => profile.volumeLitres * DENSITY_KG_PER_LITRE;

/**
 * Roughly normal, as the mean of three uniforms.
 *
 * A flat uniform makes every value in the band equally likely, which reads
 * as "random" rather than as "measured" — real lots cluster near the middle
 * of their range and only occasionally sit at an edge.
 */
function bell(random: RandomSource, centre: number, spread: number): number {
  const unit = (random.nextDouble() + random.nextDouble() + random.nextDouble()) / 3;
  return centre + (unit - 0.5) * 2 * spread;
}

/** Draws a plausible lot, optionally with a defect. */
export function randomProfile(random: RandomSource, trouble: HoneyTrouble = 'none'): HoneyProfile {
  return {
    ph: bell(random, 3.85, 0.13),
    moisture:
      trouble === 'wetLot'
        ? // Straddles the 25.8 % accepted bound and the 27.0 % tolerance bound,
          // so a wet lot sometimes warns and sometimes fails outright.
          bell(random, 26.9, 0.75)
        : // Wide enough that a sound lot occasionally grazes the edge of the
          // band. A distribution that never strays reads as manufactured.
          bell(random, 23.9, 1.95),
    electricalConductivity: bell(random, 1.9, 0.45),
    colorPfund: bell(random, 78, 32),
    rawTurbidity: bell(random, 26, 9),
    filteredTurbidity: trouble === 'cloudy' ? bell(random, 15.5, 5) : bell(random, 5.5, 2.6),
    ambientC: bell(random, 28.5, 2),
    workingC:
      trouble === 'overheated'
        ? // Over the 40 °C limit but inside the 45 °C tolerance: a warning, not
          // a scrapped batch.
          bell(random, 42.5, 1.8)
        : bell(random, 35.5, 2.2),
    volumeLitres: bell(random, 6, 2.6),
    trouble,
  };
}
