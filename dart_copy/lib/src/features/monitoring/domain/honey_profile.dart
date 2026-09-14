import 'dart:math';

import 'package:meta/meta.dart';

/// What the machine got wrong, or what arrived wrong, on one run.
///
/// Each value maps onto a different path through the assessment of §8, so a
/// demo that cycles through them exercises every verdict and every
/// recommendation the app can produce.
enum HoneyTrouble {
  /// A sound lot: every parameter sits inside its reference range.
  none,

  /// Harvested before the bees capped the pots, or stored in humid air.
  /// Moisture runs above the accepted band — the fermentation risk §12 warns
  /// about, and something filtration cannot fix.
  wetLot,

  /// The heating jacket overshot. Temperature crosses the process limit while
  /// the honey itself is fine.
  overheated,

  /// Heavy in wax, propolis and pollen. Two filtration passes do not get the
  /// clarity down to the accepted band, so another pass is worth recommending.
  cloudy,
}

/// The properties one lot of honey has before the machine touches it.
///
/// pH, moisture, conductivity and colour are characteristics of the honey
/// itself, not of the filtration run: across a single batch they move only as
/// far as sensor noise takes them. Drawing them fresh on every sample — which
/// is what the first simulator did — produced a batch whose colour wandered two
/// Pfund grades in thirty seconds, and a "faulty" run whose moisture read
/// exactly 27.9 % fifteen times over.
///
/// Turbidity is the exception, and the reason the machine exists: it is the one
/// parameter filtration changes. A profile therefore carries both the clarity
/// the lot arrives with and the clarity it can be filtered down to, and the run
/// interpolates between them.
///
/// The distributions are centred inside the reference ranges the app grades
/// against, which come from the physico-chemical survey of *Tetragonula biroi*
/// honey the project is built on.
@immutable
class HoneyProfile {
  const HoneyProfile({
    required this.ph,
    required this.moisture,
    required this.electricalConductivity,
    required this.colorPfund,
    required this.rawTurbidity,
    required this.filteredTurbidity,
    required this.ambientC,
    required this.workingC,
    required this.volumeLitres,
    this.trouble = HoneyTrouble.none,
  });

  /// Draws a plausible lot, optionally with a defect.
  factory HoneyProfile.random(
    Random random, {
    HoneyTrouble trouble = HoneyTrouble.none,
  }) {
    return HoneyProfile(
      ph: _bell(random, 3.85, 0.13),
      moisture: switch (trouble) {
        // Straddles the 25.8 % accepted bound and the 27.0 % tolerance bound,
        // so a wet lot sometimes warns and sometimes fails outright.
        HoneyTrouble.wetLot => _bell(random, 26.9, 0.75),
        // Wide enough that a sound lot occasionally grazes the edge of the
        // band. A distribution that never strays reads as manufactured.
        _ => _bell(random, 23.9, 1.95),
      },
      electricalConductivity: _bell(random, 1.90, 0.45),
      colorPfund: _bell(random, 78, 32),
      rawTurbidity: _bell(random, 26, 9),
      filteredTurbidity: switch (trouble) {
        HoneyTrouble.cloudy => _bell(random, 15.5, 5),
        _ => _bell(random, 5.5, 2.6),
      },
      ambientC: _bell(random, 28.5, 2),
      workingC: switch (trouble) {
        // Over the 40 °C limit but inside the 45 °C tolerance: a warning, not
        // a scrapped batch.
        HoneyTrouble.overheated => _bell(random, 42.5, 1.8),
        _ => _bell(random, 35.5, 2.2),
      },
      volumeLitres: _bell(random, 6, 2.6),
      trouble: trouble,
    );
  }

  /// Acidity of the lot.
  final double ph;

  /// Water content, in per cent.
  final double moisture;

  /// Conductivity in mS/cm.
  final double electricalConductivity;

  /// Colour on the Pfund scale, in mm.
  final double colorPfund;

  /// Clarity as drawn from the tank, in NTU.
  final double rawTurbidity;

  /// Clarity the two filtration stages can reach, in NTU.
  final double filteredTurbidity;

  /// Room temperature at the start of the run, in °C.
  final double ambientC;

  /// Temperature the heating jacket settles at while honey is moving, in °C.
  final double workingC;

  /// How much honey the run puts through, in litres.
  final double volumeLitres;

  final HoneyTrouble trouble;

  /// Honey is roughly 1.42 times as dense as water, which is what turns a
  /// flow rate in litres per minute into a load-cell reading in kilograms.
  static const double densityKgPerLitre = 1.42;

  /// What the load cell should read once the run finishes.
  double get yieldKg => volumeLitres * densityKgPerLitre;

  /// Roughly normal, as the mean of three uniforms.
  ///
  /// A flat uniform makes every value in the band equally likely, which reads
  /// as "random" rather than as "measured" — real lots cluster near the middle
  /// of their range and only occasionally sit at an edge.
  static double _bell(Random random, double centre, double spread) {
    final unit =
        (random.nextDouble() + random.nextDouble() + random.nextDouble()) / 3;
    return centre + (unit - 0.5) * 2 * spread;
  }
}
