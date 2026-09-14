/**
 * Geometry of the filtration machine, in the asset pack's master coordinates.
 *
 * Every SVG under `assets/honey_machine/` is authored on the same
 * `viewBox="0 0 1200 500"` canvas, so overlays need no per-asset positioning:
 * they stack full-bleed and land in register. The numbers here are copied
 * from the pack's own metadata (`assets/animation/.../metadata/*.json`) and
 * must not be nudged independently of it — moving one overlay off the shared
 * grid breaks the alignment of all of them.
 */
export const SCENE_WIDTH = 1200;
export const SCENE_HEIGHT = 500;
export const SCENE_VIEWBOX = `0 0 ${SCENE_WIDTH} ${SCENE_HEIGHT}`;

export interface Offset {
  readonly x: number;
  readonly y: number;
}

// ------------------------------------------------------------- pumps ----

/**
 * Translations that reuse the single rotor/glow asset for P1–P4. The asset
 * is drawn at P1, and the pumps are evenly spaced 170px apart.
 */
export const PUMP_OFFSETS: readonly Offset[] = [
  { x: 0, y: 0 },
  { x: 170, y: 0 },
  { x: 340, y: 0 },
  { x: 510, y: 0 },
];

/** Rotation pivot of `pump_rotor.svg`, before [PUMP_OFFSETS] is applied. */
export const ROTOR_PIVOT: Offset = { x: 303, y: 352 };

/** Seconds per rotor revolution at nominal flow. */
export const ROTOR_PERIOD_SECONDS = 1.2;

/** Centre of `pump_glow.svg`, before [PUMP_OFFSETS] is applied. */
export const GLOW_CENTRE: Offset = { x: 303, y: 338 };

/** Seconds per pump-glow pulse. */
export const GLOW_PERIOD_SECONDS = 1.1;

// ------------------------------------------------------------ hopper ----

/**
 * Inside face of the hopper. The fill and the surface are clipped to this
 * trapezoid so the honey narrows correctly as the hopper drains.
 */
export const HOPPER_CLIP_PATH = 'M 98 118 L 242 118 L 222.5 198 L 117.5 198 Z';

export const HOPPER_BOTTOM_Y = 198;
export const HOPPER_FILL_HEIGHT = 80;
export const HOPPER_WAVE_PERIOD_PX = 24;
export const HOPPER_WAVE_SECONDS = 2.0;

// --------------------------------------------------------- output jar ----

/** Inside face of the output jar, including the rounded base. */
export const JAR_CLIP_PATH =
  'M 978 318 L 1042 318 L 1037.5 362.5 Q 1036.5 373 1026 373 L 994 373 Q 983.5 373 982.5 362.5 Z';

export const JAR_BOTTOM_Y = 373;
export const JAR_FILL_HEIGHT = 55;
export const JAR_WAVE_PERIOD_PX = 18;
export const JAR_WAVE_SECONDS = 2.2;

// ------------------------------------------------------------- flow -----

/**
 * How fast honey appears to travel along the pipes, in master pixels per
 * second, at nominal flow. Shared by every route so the whole circuit
 * moves at one consistent speed.
 */
export const FLOW_PIXELS_PER_SECOND = 22.2;

/**
 * One honey route between two machine components.
 *
 * Routes are painted rather than loaded as SVGs: the source assets are three
 * strokes of the same path, and painting them means the dash phase can be
 * driven directly instead of being baked in.
 */
export interface FlowRoute {
  readonly id: string;
  /** The flow-front index at or beyond which honey moves along this route. */
  readonly activeFrom: number;
  readonly path: string;
  readonly dashOn: number;
  readonly dashOff: number;
  readonly strokeWidth: number;
  readonly glowWidth: number;
  readonly core: string;
  readonly highlight: string;
  readonly glow: string;
  readonly opacity: number;
}

/** An exposed pipe run: full weight, brighter, matching the 8px pipe bore. */
const exposed = (id: string, activeFrom: number, path: string): FlowRoute => ({
  id,
  activeFrom,
  path,
  dashOn: 11,
  dashOff: 9,
  strokeWidth: 4.8,
  glowWidth: 8,
  core: '#E8A62D',
  highlight: '#FFD974',
  glow: '#E49A23',
  opacity: 0.98,
});

/**
 * A transfer hidden inside the machine: slightly thinner and dimmer, so it
 * reads as internal movement rather than a visible pipe.
 */
const internal = (id: string, activeFrom: number, path: string): FlowRoute => ({
  id,
  activeFrom,
  path,
  dashOn: 9,
  dashOff: 8,
  strokeWidth: 4.4,
  glowWidth: 7.4,
  core: '#E7A12A',
  highlight: '#FFD975',
  glow: '#D98D1D',
  opacity: 0.92,
});

/** The eight registered flow routes, in process order. */
export const FLOW_ROUTES: readonly FlowRoute[] = [
  // 1 — hopper outlet down into P1.
  exposed('hopper_to_p1', 1, 'M 170 273 H 190 V 335 H 270'),
  // 2 — P1 up into Filter 1.
  exposed('p1_to_filter1', 2, 'M 336 335 H 390 V 315 H 425'),
  // 3 — Filter 1 down into P2, internal.
  internal('filter1_to_p2', 2, 'M 410 266 V 300 C 410 320 420 335 440 335'),
  // 4 — P2 up into Filter 2.
  exposed('p2_to_filter2', 3, 'M 505 335 H 560 V 315 H 595'),
  // 5 — Filter 2 down into P3, internal.
  internal('filter2_to_p3', 3, 'M 580 266 V 300 C 580 320 590 335 610 335'),
  // 6 — P3 up into Filter 3.
  exposed('p3_to_filter3', 4, 'M 675 335 H 730 V 315 H 765'),
  // 7 — Filter 3 down into P4, internal.
  internal('filter3_to_p4', 4, 'M 750 266 V 300 C 750 320 760 335 780 335'),
  // 8 — P4 out to the jar. The pack splits this into the exact exposed pipe
  // plus a short conceptual nozzle into the jar; the combined path is drawn
  // as one exposed route, which is within a pixel of the split rendering.
  exposed('p4_to_output_jar', 5, 'M 845 335 H 930 V 305 H 965 C 972 305 979 309 982 318'),
];

// ------------------------------------------------- control panel slots ---

/** Centre of the connectivity indicator, top slot on the control panel. */
export const CONNECTIVITY_SLOT: Offset = { x: 1071, y: 141 };

/** Centre of the fault indicator, middle slot. */
export const FAULT_SLOT: Offset = { x: 1071, y: 166 };

export const START_BUTTON: Offset = { x: 966, y: 232 };
export const STOP_BUTTON: Offset = { x: 1015, y: 232 };
