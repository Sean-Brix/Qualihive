/**
 * Pfund scale colour grades (mm Pfund).
 *
 * The reference study graded local *Tetragonula biroi* honey between
 * extra light amber and dark amber, so those two bound the acceptable band.
 */
export type HoneyColorGrade =
  | 'waterWhite'
  | 'extraWhite'
  | 'white'
  | 'extraLightAmber'
  | 'lightAmber'
  | 'amber'
  | 'darkAmber';

export interface HoneyColorGradeInfo {
  readonly name: HoneyColorGrade;
  readonly label: string;
  readonly minPfund: number;
  readonly maxPfund: number;
}

export const HONEY_COLOR_GRADES: readonly HoneyColorGradeInfo[] = [
  { name: 'waterWhite', label: 'Water white', minPfund: 0, maxPfund: 8 },
  { name: 'extraWhite', label: 'Extra white', minPfund: 8, maxPfund: 17 },
  { name: 'white', label: 'White', minPfund: 17, maxPfund: 34 },
  { name: 'extraLightAmber', label: 'Extra light amber', minPfund: 34, maxPfund: 50 },
  { name: 'lightAmber', label: 'Light amber', minPfund: 50, maxPfund: 85 },
  { name: 'amber', label: 'Amber', minPfund: 85, maxPfund: 114 },
  { name: 'darkAmber', label: 'Dark amber', minPfund: 114, maxPfund: 150 },
];

/** Lowest grade accepted by the reference study. */
export const ACCEPTABLE_FLOOR: HoneyColorGrade = 'extraLightAmber';

/** Highest grade accepted by the reference study. */
export const ACCEPTABLE_CEILING: HoneyColorGrade = 'darkAmber';

export function gradeInfo(grade: HoneyColorGrade): HoneyColorGradeInfo {
  return HONEY_COLOR_GRADES.find((g) => g.name === grade)!;
}

export function gradeLabel(grade: HoneyColorGrade): string {
  return gradeInfo(grade).label;
}

export function gradeIndex(grade: HoneyColorGrade): number {
  return HONEY_COLOR_GRADES.findIndex((g) => g.name === grade);
}

export function isGradeAcceptable(grade: HoneyColorGrade): boolean {
  const index = gradeIndex(grade);
  return index >= gradeIndex(ACCEPTABLE_FLOOR) && index <= gradeIndex(ACCEPTABLE_CEILING);
}

export function gradeFromPfund(pfund: number): HoneyColorGrade {
  for (const grade of HONEY_COLOR_GRADES) {
    if (pfund < grade.maxPfund) return grade.name;
  }
  return 'darkAmber';
}

const normaliseKey = (value: string) => value.trim().toLowerCase().replace(/[ _-]/g, '');

/**
 * Matches a classification string sent by the device, e.g. `"Amber"`.
 * Returns null when the label is not one of the Pfund grades.
 */
export function gradeFromLabel(label: string | null | undefined): HoneyColorGrade | null {
  if (label == null) return null;
  const key = normaliseKey(label);
  if (key.length === 0) return null;
  for (const grade of HONEY_COLOR_GRADES) {
    if (grade.name.toLowerCase() === key) return grade.name;
    if (grade.label.toLowerCase().replace(/ /g, '') === key) return grade.name;
  }
  return null;
}

/**
 * A colour reading from the TCS-family colour sensor.
 *
 * The specification (§4, §11) has the device send RGB plus an optional
 * classification string, and asks the app to store the raw RGB while showing
 * a human-readable grade. All three parts are optional so the app can work
 * with firmware that sends only RGB, only a Pfund value, or only a label.
 */
export interface HoneyColor {
  readonly red?: number | null;
  readonly green?: number | null;
  readonly blue?: number | null;
  /** Millimetre Pfund, when the device reports it directly. */
  readonly pfund?: number | null;
  /** Classification string as sent by the device, e.g. `"Amber"`. */
  readonly label?: string | null;
}

export function hasRgb(color: HoneyColor): boolean {
  return color.red != null && color.green != null && color.blue != null;
}

export function isColorEmpty(color: HoneyColor): boolean {
  return !hasRgb(color) && color.pfund == null && color.label == null;
}

/** `#D78E38`, for reports, CSV and swatches. Null when the device sent no RGB. */
export function colorHex(color: HoneyColor): string | null {
  if (!hasRgb(color)) return null;
  const channel = (v: number) => v.toString(16).padStart(2, '0');
  return `#${channel(color.red!)}${channel(color.green!)}${channel(color.blue!)}`.toUpperCase();
}

/**
 * **Provisional calibration.** Specification §5 and §12 record that the
 * researchers have not yet defined the RGB → colour-category boundaries, so
 * this converts perceived lightness to the Pfund scale linearly: bright
 * honey is water-white (0 mm), near-black honey is dark amber (150 mm).
 *
 * It is deliberately the only place the conversion lives. When the
 * researchers supply the real calibration, replace the body of this function
 * and nothing else in the app changes.
 */
export function estimatePfundFromRgb(r: number, g: number, b: number): number {
  // Rec. 601 luma — closer to perceived brightness than a plain mean.
  const luma = 0.299 * r + 0.587 * g + 0.114 * b;
  const pfund = 150 * (1 - luma / 255);
  return Math.min(150, Math.max(0, pfund));
}

/**
 * Pfund value used for grading, in order of trust: the value the device
 * measured, then the grade it named, then [estimatePfundFromRgb].
 */
export function effectivePfund(color: HoneyColor): number | null {
  if (color.pfund != null) return color.pfund;

  const named = gradeFromLabel(color.label);
  if (named != null) {
    const info = gradeInfo(named);
    return (info.minPfund + info.maxPfund) / 2;
  }

  return hasRgb(color) ? estimatePfundFromRgb(color.red!, color.green!, color.blue!) : null;
}

/**
 * The grade to display: the device's own classification wins, otherwise
 * whatever [effectivePfund] resolves to.
 */
export function colorGrade(color: HoneyColor): HoneyColorGrade | null {
  const named = gradeFromLabel(color.label);
  if (named != null) return named;

  const value = effectivePfund(color);
  return value == null ? null : gradeFromPfund(value);
}

/** What to show the user — the device's label if it sent one, else the derived grade. */
export function colorDisplayLabel(color: HoneyColor): string | null {
  const trimmed = color.label?.trim();
  if (trimmed) return trimmed;
  const grade = colorGrade(color);
  return grade == null ? null : gradeLabel(grade);
}

export function colorsEqual(
  a: HoneyColor | null | undefined,
  b: HoneyColor | null | undefined,
): boolean {
  if (a === b) return true;
  if (a == null || b == null) return false;
  return (
    (a.red ?? null) === (b.red ?? null) &&
    (a.green ?? null) === (b.green ?? null) &&
    (a.blue ?? null) === (b.blue ?? null) &&
    (a.pfund ?? null) === (b.pfund ?? null) &&
    (a.label ?? null) === (b.label ?? null)
  );
}
