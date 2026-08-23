import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../monitoring/domain/quality_spec.dart';
import 'threshold_dao.dart';

/// Builds the active [QualityStandard] by laying operator edits over the
/// built-in defaults.
///
/// Specification §12 records that the approved reference ranges are still to
/// be confirmed by the researchers, so the standard has to be changeable
/// without a rebuild. A parameter with no row here uses its default, which is
/// also what "Reset" does — it deletes the row rather than writing the default
/// back, so a later change to the defaults reaches an already-installed app.
class ThresholdRepository {
  const ThresholdRepository(this._dao);

  final ThresholdDao _dao;

  Stream<QualityStandard> watchStandard() =>
      _dao.watchAll().map(_applyOverrides);

  Future<QualityStandard> getStandard() async =>
      _applyOverrides(await _dao.getAll());

  Future<void> save(ParameterSpec spec) {
    return _dao.upsert(
      ThresholdsCompanion.insert(
        parameter: spec.parameter,
        minValue: Value(spec.min),
        maxValue: Value(spec.max),
        warnMin: Value(spec.warnMin),
        warnMax: Value(spec.warnMax),
        rated: Value(spec.rated),
        source: const Value(ThresholdSource.operatorEdited),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> reset(SensorParameter parameter) =>
      _dao.reset(parameter.name);

  Future<void> resetAll() => _dao.resetAll();

  QualityStandard _applyOverrides(List<ThresholdRow> rows) {
    var standard = QualityStandard.defaults;

    for (final row in rows) {
      final base = QualityStandard.defaultOf(row.parameter);

      // Written positionally rather than through copyWith because an override
      // that clears a bound has to survive: copyWith's `??` would fall back to
      // the default value instead of keeping the null.
      standard = standard.withSpec(
        ParameterSpec(
          parameter: base.parameter,
          label: base.label,
          shortLabel: base.shortLabel,
          unit: base.unit,
          min: row.minValue,
          max: row.maxValue,
          warnMin: row.warnMin,
          warnMax: row.warnMax,
          rated: row.rated,
          decimals: base.decimals,
          source: row.source,
          note: base.note,
        ),
      );
    }

    return standard;
  }
}
