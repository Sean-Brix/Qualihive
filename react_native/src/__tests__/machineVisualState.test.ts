import { STAGE_SEQUENCE, type FiltrationStage } from '@/features/monitoring/domain/machineState';
import {
  deriveVisualState,
  filterActive,
  flowFront,
  isRunning,
  pumpActive,
  showsOnline,
} from '@/features/monitoring/domain/machineVisualState';
import {
  FLOW_ROUTES,
  HOPPER_BOTTOM_Y,
  HOPPER_FILL_HEIGHT,
  JAR_BOTTOM_Y,
  JAR_FILL_HEIGHT,
} from '@/features/monitoring/presentation/digitalTwin/machineScene';

const running = (stage: FiltrationStage, weightKg?: number) =>
  deriveVisualState({
    connected: true,
    status: 'running',
    stage,
    weightKg,
    lastReadingAt: new Date(),
  });

describe('flow front', () => {
  test('is zero while nothing is running', () => {
    expect(flowFront(deriveVisualState({ connected: true, status: 'ready', stage: 'idle' }))).toBe(0);
  });

  test('advances with the stage', () => {
    expect(flowFront(running('extracting'))).toBe(1);
    expect(flowFront(running('primaryFiltration'))).toBe(2);
    expect(flowFront(running('secondaryFiltration'))).toBe(3);
    expect(flowFront(running('qualityAssessment'))).toBe(4);
    expect(flowFront(running('finalTransfer'))).toBe(5);
  });

  test('drops to zero once the batch is finished', () => {
    expect(flowFront(running('completed'))).toBe(0);
  });

  test('drops to zero on a machine fault, whatever the stage says', () => {
    const faulted = deriveVisualState({ connected: true, status: 'error', stage: 'secondaryFiltration' });
    expect(faulted.fault).toBe('critical');
    expect(flowFront(faulted)).toBe(0);
    expect(isRunning(faulted)).toBe(false);
  });

  test('a paused cycle keeps its extent but stops moving', () => {
    const paused = deriveVisualState({ connected: true, status: 'paused', stage: 'secondaryFiltration' });
    expect(flowFront(paused)).toBe(3);
    expect(isRunning(paused)).toBe(false);
  });
});

describe('pumps and filters', () => {
  test('every route that is lit has its feeding pump running', () => {
    for (const stage of STAGE_SEQUENCE) {
      const state = running(stage);
      for (const route of FLOW_ROUTES) {
        if (flowFront(state) < route.activeFrom) continue;
        // A route only ever activates once the machine has reached the
        // stage that drives it, so the pump at that index must be on.
        expect(pumpActive(state, Math.min(4, Math.max(1, route.activeFrom)))).toBe(true);
      }
    }
  });

  test('filters light up one stage after their feed pump', () => {
    const primary = running('primaryFiltration');
    expect(filterActive(primary, 1)).toBe(true);
    expect(filterActive(primary, 2)).toBe(false);
    expect(filterActive(primary, 3)).toBe(false);

    const quality = running('qualityAssessment');
    expect(filterActive(quality, 1)).toBe(true);
    expect(filterActive(quality, 2)).toBe(true);
    expect(filterActive(quality, 3)).toBe(true);
  });
});

describe('levels', () => {
  test('jar fills in proportion to net weight and clamps at capacity', () => {
    expect(running('finalTransfer', 0).jarLevel).toBe(0);
    expect(running('finalTransfer', 0.5).jarLevel).toBeCloseTo(0.5, 9);
    expect(running('finalTransfer', 3).jarLevel).toBe(1);
  });

  test('an overfull jar raises a warning', () => {
    expect(running('finalTransfer', 1.4).fault).toBe('warning');
  });

  test('the indicative hopper level drains as the batch progresses', () => {
    const early = running('extracting').hopperLevel;
    const late = running('finalTransfer').hopperLevel;
    expect(early).toBeGreaterThan(late);
    expect(early).toBeLessThanOrEqual(1);
    expect(late).toBeGreaterThan(0);
  });

  test('a faulted or paused cycle keeps the honey it had', () => {
    const faulted = deriveVisualState({ connected: true, status: 'error', stage: 'secondaryFiltration' });
    const paused = deriveVisualState({ connected: true, status: 'paused', stage: 'secondaryFiltration' });
    const expected = running('secondaryFiltration').hopperLevel;
    expect(faulted.hopperLevel).toBe(expected);
    expect(paused.hopperLevel).toBe(expected);
    expect(expected).toBeGreaterThan(0);
  });

  test('an idle machine shows an empty hopper', () => {
    expect(deriveVisualState({ connected: true, status: 'ready', stage: 'idle' }).hopperLevel).toBe(0);
  });
});

describe('connectivity', () => {
  test('a link that has gone quiet reads as offline', () => {
    const now = new Date();
    const fresh = deriveVisualState({ connected: true, status: 'running', stage: 'extracting', lastReadingAt: now });
    const quiet = deriveVisualState({
      connected: true,
      status: 'running',
      stage: 'extracting',
      lastReadingAt: new Date(now.getTime() - 60_000),
    });
    expect(showsOnline(fresh, now)).toBe(true);
    expect(showsOnline(quiet, now)).toBe(false);
  });
});

describe('quality', () => {
  test('an out-of-specification batch warns without faulting the machine', () => {
    const state = deriveVisualState({
      connected: true,
      status: 'running',
      stage: 'qualityAssessment',
      assessment: 'outsideParameters',
    });
    expect(state.fault).toBe('warning');
    // Bad honey is not a machine fault.
    expect(isRunning(state)).toBe(true);
    expect(flowFront(state)).toBe(4);
  });
});

describe('scene geometry', () => {
  test('vessel surfaces sit at the levels the metadata specifies', () => {
    const hopperSurfaceY = (level: number) => HOPPER_BOTTOM_Y - HOPPER_FILL_HEIGHT * level;
    const jarSurfaceY = (level: number) => JAR_BOTTOM_Y - JAR_FILL_HEIGHT * level;
    expect(hopperSurfaceY(0)).toBe(198);
    expect(hopperSurfaceY(1)).toBe(118);
    expect(jarSurfaceY(0)).toBe(373);
    expect(jarSurfaceY(0.25)).toBeCloseTo(359.25, 9);
    expect(jarSurfaceY(1)).toBe(318);
  });

  test('every route names the pump that feeds it', () => {
    for (const route of FLOW_ROUTES) {
      expect(route.activeFrom).toBeGreaterThanOrEqual(1);
      expect(route.activeFrom).toBeLessThanOrEqual(5);
      expect(route.path.startsWith('M ')).toBe(true);
    }
  });
});
