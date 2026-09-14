import { useEffect, useMemo, useState, type FC, type ReactNode } from 'react';
import { StyleSheet, View, type LayoutChangeEvent } from 'react-native';
import Animated, {
  Easing,
  useAnimatedProps,
  useAnimatedStyle,
  useFrameCallback,
  useSharedValue,
  withTiming,
  type SharedValue,
} from 'react-native-reanimated';
import Svg, { ClipPath, Defs, FeColorMatrix, FeGaussianBlur, Filter, G, Path } from 'react-native-svg';

import Filter1Overlay from '@assets/honey_machine/filter1_processing_overlay.svg';
import Filter2Overlay from '@assets/honey_machine/filter2_processing_overlay.svg';
import Filter3Overlay from '@assets/honey_machine/filter3_processing_overlay.svg';
import HopperFill from '@assets/honey_machine/hopper_honey_fill.svg';
import HopperWave from '@assets/honey_machine/hopper_surface_wave.svg';
import MachineBase from '@assets/honey_machine/machine_base.svg';
import OfflineStatus from '@assets/honey_machine/offline_disconnected_status.svg';
import OnlineStatus from '@assets/honey_machine/online_connected_status.svg';
import JarFill from '@assets/honey_machine/output_jar_honey_fill.svg';
import JarWave from '@assets/honey_machine/output_jar_surface_wave.svg';
import PumpGlow from '@assets/honey_machine/pump_glow.svg';
import PumpRotor from '@assets/honey_machine/pump_rotor.svg';
import StartButton from '@assets/honey_machine/start_button_active.svg';
import StopButton from '@assets/honey_machine/stop_button_active.svg';
import WarningOverlay from '@assets/honey_machine/warning_error_overlay.svg';

import {
  filterActive,
  flowFront,
  isAnimated,
  isRunning,
  pumpActive,
  semanticLabel,
  showsOnline,
  startLatched,
  stopLatched,
  type MachineVisualState,
} from '../../domain/machineVisualState';
import {
  FLOW_PIXELS_PER_SECOND,
  FLOW_ROUTES,
  GLOW_CENTRE,
  GLOW_PERIOD_SECONDS,
  HOPPER_CLIP_PATH,
  HOPPER_FILL_HEIGHT,
  HOPPER_WAVE_PERIOD_PX,
  HOPPER_WAVE_SECONDS,
  JAR_CLIP_PATH,
  JAR_FILL_HEIGHT,
  JAR_WAVE_PERIOD_PX,
  JAR_WAVE_SECONDS,
  PUMP_OFFSETS,
  ROTOR_PERIOD_SECONDS,
  ROTOR_PIVOT,
  SCENE_HEIGHT,
  SCENE_VIEWBOX,
  SCENE_WIDTH,
  type FlowRoute,
  type Offset,
} from './machineScene';

const AnimatedPath = Animated.createAnimatedComponent(Path);
const AnimatedG = Animated.createAnimatedComponent(G);

/** A 0–1 triangle-free oscillation for indicator pulses. */
function pulse(seconds: number, period: number): number {
  'worklet';
  return (Math.sin((seconds / period) * 2 * Math.PI) + 1) / 2;
}

function lerp(a: number, b: number, t: number): number {
  'worklet';
  return a + (b - a) * t;
}

/**
 * Shifts the amber fault overlay to red without flattening it: green and
 * blue are pulled down, so the dark exclamation mark stays dark against a
 * now-red triangle. The asset pack suggests exactly this for critical
 * faults rather than shipping a second overlay.
 */
const CRITICAL_TINT = '1 0 0 0 0  0 0.45 0 0 0  0 0 0.5 0 0  0 0 0 1 0';

interface Clocks {
  /** Wall-clock seconds since mount, for indicator pulses. */
  clock: SharedValue<number>;
  /** Distance the honey dashes have travelled, in scene pixels. */
  flowPhase: SharedValue<number>;
  /** Rotor rotation, in degrees. */
  rotorAngle: SharedValue<number>;
  /** Honey-surface drift, in whole wave periods. */
  wavePhase: SharedValue<number>;
}

/**
 * A live drawing of the filtration machine — specification §1 and §3.
 *
 * The whole scene is stacked full-bleed inside a 1200×500 box and scaled to
 * fit, so every overlay stays in register with the base drawing and no layer
 * needs positioning of its own.
 *
 * Two clocks drive it. Process motion — flowing honey, spinning rotors,
 * drifting honey surfaces — advances only while the machine is running, and
 * is accumulated rather than derived from elapsed time so that pausing
 * freezes it in place instead of snapping it back to the start. Indicators —
 * the connectivity heartbeat, the pump halos, the fault badge — pulse from
 * wall-clock time regardless, because they report state rather than movement.
 *
 * Everything animated is a Reanimated shared value updated on the UI thread,
 * so the JS thread does nothing per frame.
 */
export function MachineDigitalTwin({ state }: { state: MachineVisualState }) {
  const [width, setWidth] = useState(0);
  const scale = width / SCENE_WIDTH;

  const clock = useSharedValue(0);
  const flowPhase = useSharedValue(0);
  const rotorAngle = useSharedValue(0);
  const wavePhase = useSharedValue(0);
  const running = useSharedValue(isRunning(state) ? 1 : 0);
  const speed = useSharedValue(state.flowSpeed);
  const hopperLevel = useSharedValue(state.hopperLevel);
  const jarLevel = useSharedValue(state.jarLevel);

  useEffect(() => {
    running.value = isRunning(state) ? 1 : 0;
    speed.value = state.flowSpeed;
    // Levels are tweened so a step change in the reported weight reads as the
    // jar filling rather than the honey teleporting.
    const timing = { duration: 700, easing: Easing.out(Easing.cubic) };
    hopperLevel.value = withTiming(state.hopperLevel, timing);
    jarLevel.value = withTiming(state.jarLevel, timing);
  }, [state, running, speed, hopperLevel, jarLevel]);

  const frame = useFrameCallback((info) => {
    // Clamped so a dropped frame or a backgrounded app resumes smoothly
    // instead of jumping the honey forward by however long it was away.
    const delta = Math.min(0.05, Math.max(0, (info.timeSincePreviousFrame ?? 0) / 1000));
    clock.value += delta;

    if (running.value > 0) {
      const s = speed.value;
      flowPhase.value += delta * FLOW_PIXELS_PER_SECOND * s;
      rotorAngle.value += (delta / ROTOR_PERIOD_SECONDS) * 360 * s;
      wavePhase.value += delta / HOPPER_WAVE_SECONDS;
    }
  }, false);

  // A machine sitting idle and connected animates nothing, so the ticker
  // stops entirely; level tweens run on their own timers.
  const animated = isAnimated(state);
  useEffect(() => {
    frame.setActive(animated);
  }, [animated, frame]);

  const clocks: Clocks = useMemo(
    () => ({ clock, flowPhase, rotorAngle, wavePhase }),
    [clock, flowPhase, rotorAngle, wavePhase],
  );

  const online = showsOnline(state, new Date());
  const front = flowFront(state);
  const runningNow = isRunning(state);

  return (
    <View
      accessible
      accessibilityRole="image"
      accessibilityLabel={semanticLabel(state)}
      style={styles.scene}
      onLayout={(e: LayoutChangeEvent) => setWidth(e.nativeEvent.layout.width)}
    >
      {/* The base machine never changes. */}
      <MachineBase width="100%" height="100%" style={StyleSheet.absoluteFill} />

      {width > 0 && (
        <>
          {/* Running pumps sit in a soft green halo. The asset wants to be
              behind the pump body, but the body lives inside the flat base
              drawing, so it goes on top at a restrained opacity instead. */}
          {[1, 2, 3, 4].map(
            (pump) =>
              pumpActive(state, pump) && (
                <PumpGlowLayer key={`glow-${pump}`} offset={PUMP_OFFSETS[pump - 1]} scale={scale} clocks={clocks} />
              ),
          )}

          {/* Honey draining from the hopper and collecting in the jar. */}
          <Vessel
            level={hopperLevel}
            wavePhase={wavePhase}
            waveScale={1}
            clip={HOPPER_CLIP_PATH}
            clipId="hopperClip"
            Fill={HopperFill}
            Wave={HopperWave}
            fillHeight={HOPPER_FILL_HEIGHT}
            wavePeriodPx={HOPPER_WAVE_PERIOD_PX}
          />
          <Vessel
            level={jarLevel}
            wavePhase={wavePhase}
            waveScale={HOPPER_WAVE_SECONDS / JAR_WAVE_SECONDS}
            clip={JAR_CLIP_PATH}
            clipId="jarClip"
            Fill={JarFill}
            Wave={JarWave}
            fillHeight={JAR_FILL_HEIGHT}
            wavePeriodPx={JAR_WAVE_PERIOD_PX}
          />

          {/* Honey moving through the pipes. Paused keeps the honey visible
              but dimmed, so a held cycle looks held rather than finished. */}
          <FlowLayer front={front} intensity={runningNow ? 1 : 0.45} phase={flowPhase} />

          {/* Filter media, tinted while that stage is processing. */}
          {filterActive(state, 1) && (
            <PulsingLayer clock={clock} from={0.72} to={0.96} period={1.8} steady={runningNow ? null : 0.5}>
              <Filter1Overlay width="100%" height="100%" />
            </PulsingLayer>
          )}
          {filterActive(state, 2) && (
            <PulsingLayer clock={clock} from={0.72} to={0.96} period={1.8} steady={runningNow ? null : 0.5}>
              <Filter2Overlay width="100%" height="100%" />
            </PulsingLayer>
          )}
          {filterActive(state, 3) && (
            <PulsingLayer clock={clock} from={0.72} to={0.96} period={1.8} steady={runningNow ? null : 0.5}>
              <Filter3Overlay width="100%" height="100%" />
            </PulsingLayer>
          )}

          {/* Impellers, turning at the reported flow rate. */}
          {[1, 2, 3, 4].map(
            (pump) =>
              pumpActive(state, pump) && (
                <RotorLayer key={`rotor-${pump}`} offset={PUMP_OFFSETS[pump - 1]} scale={scale} angle={rotorAngle} />
              ),
          )}

          {/* Control panel: the START button latches while a cycle runs, STOP
              once it is paused, finished or faulted. */}
          {startLatched(state) ? (
            <PulsingLayer clock={clock} from={0.68} to={1} period={1.1}>
              <StartButton width="100%" height="100%" />
            </PulsingLayer>
          ) : (
            stopLatched(state) && (
              <View style={StyleSheet.absoluteFill} pointerEvents="none">
                <StopButton width="100%" height="100%" />
              </View>
            )
          )}

          {/* Connectivity indicator. Steady green with a slow heartbeat when
              the link is healthy, a slow red pulse when it is down or quiet. */}
          {online ? (
            <PulsingLayer clock={clock} from={0.82} to={1} period={2}>
              <OnlineStatus width="100%" height="100%" />
            </PulsingLayer>
          ) : (
            <PulsingLayer clock={clock} from={0.4} to={1} period={1.5}>
              <OfflineStatus width="100%" height="100%" />
            </PulsingLayer>
          )}

          {/* Faults outrank everything else on the panel. */}
          {state.fault === 'critical' && (
            <PulsingLayer clock={clock} from={0.55} to={1} period={0.9}>
              <Svg viewBox={SCENE_VIEWBOX} width="100%" height="100%">
                <Defs>
                  <Filter id="criticalTint">
                    <FeColorMatrix type="matrix" values={CRITICAL_TINT} />
                  </Filter>
                </Defs>
                <G filter="url(#criticalTint)">
                  <WarningOverlay width={SCENE_WIDTH} height={SCENE_HEIGHT} />
                </G>
              </Svg>
            </PulsingLayer>
          )}
          {state.fault === 'warning' && (
            <PulsingLayer clock={clock} from={0.45} to={0.95} period={1.5}>
              <WarningOverlay width="100%" height="100%" />
            </PulsingLayer>
          )}
        </>
      )}
    </View>
  );
}

/** A full-canvas overlay whose opacity breathes with the wall clock. */
function PulsingLayer({
  clock,
  from,
  to,
  period,
  steady = null,
  children,
}: {
  clock: SharedValue<number>;
  from: number;
  to: number;
  period: number;
  /** When set, holds this opacity instead of pulsing. */
  steady?: number | null;
  children: ReactNode;
}) {
  const style = useAnimatedStyle(
    () => ({
      opacity: steady ?? lerp(from, to, pulse(clock.value, period)),
    }),
    [from, to, period, steady],
  );
  return (
    <Animated.View style={[StyleSheet.absoluteFill, style]} pointerEvents="none">
      {children}
    </Animated.View>
  );
}

/**
 * Rotates a full-canvas layer about a scene point.
 *
 * React Native rotates a view about its centre, so the pivot is moved to the
 * centre, the rotation applied, and the pivot moved back — the same matrix
 * the Flutter build composes, expressed in view pixels.
 */
function pivotTransform(pivot: Offset, offset: Offset, scale: number) {
  'worklet';
  const cx = (SCENE_WIDTH / 2) * scale;
  const cy = (SCENE_HEIGHT / 2) * scale;
  return {
    dx: (pivot.x + offset.x) * scale - cx,
    dy: (pivot.y + offset.y) * scale - cy,
    ox: offset.x * scale,
    oy: offset.y * scale,
  };
}

/** One pump impeller, reused from the single rotor asset drawn at P1. */
function RotorLayer({
  offset,
  scale,
  angle,
}: {
  offset: Offset;
  scale: number;
  angle: SharedValue<number>;
}) {
  const style = useAnimatedStyle(() => {
    const { dx, dy, ox, oy } = pivotTransform(ROTOR_PIVOT, offset, scale);
    return {
      transform: [
        { translateX: dx },
        { translateY: dy },
        { rotate: `${angle.value}deg` },
        { translateX: -dx + ox },
        { translateY: -dy + oy },
      ],
    };
  }, [offset, scale]);

  return (
    <Animated.View style={[StyleSheet.absoluteFill, style]} pointerEvents="none">
      <PumpRotor width="100%" height="100%" />
    </Animated.View>
  );
}

/** The active-pump halo, pulsing in place. */
function PumpGlowLayer({
  offset,
  scale,
  clocks,
}: {
  offset: Offset;
  scale: number;
  clocks: Clocks;
}) {
  const style = useAnimatedStyle(() => {
    const phase = pulse(clocks.clock.value, GLOW_PERIOD_SECONDS);
    const grow = lerp(0.96, 1.06, phase);
    const { dx, dy, ox, oy } = pivotTransform(GLOW_CENTRE, offset, scale);
    return {
      opacity: lerp(0.18, 0.5, phase),
      transform: [
        { translateX: dx },
        { translateY: dy },
        { scale: grow },
        { translateX: -dx + ox },
        { translateY: -dy + oy },
      ],
    };
  }, [offset, scale]);

  return (
    <Animated.View style={[StyleSheet.absoluteFill, style]} pointerEvents="none">
      <PumpGlow width="100%" height="100%" />
    </Animated.View>
  );
}

/**
 * Honey inside the hopper or the output jar.
 *
 * The vessel's clip stays fixed and only the honey moves inside it, so the
 * hopper's taper narrows the surface as it drains instead of the whole
 * drawing being squashed. The fill slides up from the bottom; the surface
 * line rides on top of it and drifts sideways.
 */
function Vessel({
  level,
  wavePhase,
  waveScale,
  clip,
  clipId,
  Fill,
  Wave,
  fillHeight,
  wavePeriodPx,
}: {
  level: SharedValue<number>;
  wavePhase: SharedValue<number>;
  waveScale: number;
  clip: string;
  clipId: string;
  Fill: FC<{ width?: number | string; height?: number | string }>;
  Wave: FC<{ width?: number | string; height?: number | string }>;
  fillHeight: number;
  wavePeriodPx: number;
}) {
  const fillProps = useAnimatedProps(() => ({
    y: fillHeight * (1 - level.value),
  }));

  const waveProps = useAnimatedProps(() => {
    const phase = (wavePhase.value * waveScale) % 1;
    // A nearly empty vessel fades its surface line out rather than leaving a
    // bright meniscus sitting on nothing.
    const surfaceFade = Math.min(1, Math.max(0, level.value / 0.05));
    return {
      x: -phase * wavePeriodPx,
      y: -fillHeight * level.value,
      opacity: surfaceFade,
    };
  }, [waveScale, wavePeriodPx, fillHeight]);

  const containerStyle = useAnimatedStyle(() => ({
    opacity: level.value <= 0.01 ? 0 : 1,
  }));

  return (
    <Animated.View style={[StyleSheet.absoluteFill, containerStyle]} pointerEvents="none">
      <Svg viewBox={SCENE_VIEWBOX} width="100%" height="100%">
        <Defs>
          <ClipPath id={clipId}>
            <Path d={clip} />
          </ClipPath>
        </Defs>
        <G clipPath={`url(#${clipId})`}>
          <AnimatedG animatedProps={fillProps}>
            <Fill width={SCENE_WIDTH} height={SCENE_HEIGHT} />
          </AnimatedG>
          <AnimatedG animatedProps={waveProps}>
            <Wave width={SCENE_WIDTH} height={SCENE_HEIGHT} />
          </AnimatedG>
        </G>
      </Svg>
    </Animated.View>
  );
}

/**
 * Paints the eight honey routes as moving dashes inside the machine's pipes.
 *
 * All eight are one SVG rather than eight stacked assets: the routes are only
 * three strokes each, and the dash phase advances at a constant number of
 * pixels per second across every route, so the whole circuit moves as one
 * system rather than each pipe running at its own speed.
 */
function FlowLayer({
  front,
  intensity,
  phase,
}: {
  front: number;
  intensity: number;
  phase: SharedValue<number>;
}) {
  if (intensity <= 0.01 || front <= 0) return null;

  return (
    <View style={StyleSheet.absoluteFill} pointerEvents="none">
      <Svg viewBox={SCENE_VIEWBOX} width="100%" height="100%">
        <Defs>
          <Filter id="flowGlow" x="-20%" y="-20%" width="140%" height="140%">
            <FeGaussianBlur stdDeviation="2.1" />
          </Filter>
        </Defs>
        {FLOW_ROUTES.filter((route) => front >= route.activeFrom).map((route) => (
          <RouteStrokes key={route.id} route={route} intensity={intensity} phase={phase} />
        ))}
      </Svg>
    </View>
  );
}

function RouteStrokes({
  route,
  intensity,
  phase,
}: {
  route: FlowRoute;
  intensity: number;
  phase: SharedValue<number>;
}) {
  const alphaValue = intensity * route.opacity;

  // Increasing the phase moves the honey from the start of the pipe towards
  // the end, which in SVG terms is a shrinking dash offset.
  const dashProps = useAnimatedProps(() => ({ strokeDashoffset: -phase.value }));
  // A thin warm highlight, offset a little way behind the dash it rides on,
  // exactly as the source asset stacks it.
  const highlightProps = useAnimatedProps(() => ({ strokeDashoffset: -(phase.value - 1.5) }));

  return (
    <G>
      {/* A soft amber bloom sitting just inside the pipe bore. */}
      <Path
        d={route.path}
        fill="none"
        stroke={route.glow}
        strokeOpacity={0.22 * alphaValue}
        strokeWidth={route.glowWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
        filter="url(#flowGlow)"
      />
      <AnimatedPath
        d={route.path}
        fill="none"
        stroke={route.core}
        strokeOpacity={alphaValue}
        strokeWidth={route.strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeDasharray={[route.dashOn, route.dashOff]}
        animatedProps={dashProps}
      />
      <AnimatedPath
        d={route.path}
        fill="none"
        stroke={route.highlight}
        strokeOpacity={0.72 * alphaValue}
        strokeWidth={1.25}
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeDasharray={[route.dashOn, route.dashOff]}
        animatedProps={highlightProps}
      />
    </G>
  );
}

const styles = StyleSheet.create({
  scene: { width: '100%', aspectRatio: SCENE_WIDTH / SCENE_HEIGHT },
});
