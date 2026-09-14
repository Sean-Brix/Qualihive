import { useState } from 'react';
import { Alert, ScrollView, StyleSheet, Switch, View } from 'react-native';

import { Button, IconButton } from '@/core/components/Button';
import { Card } from '@/core/components/Card';
import { Icon } from '@/core/components/Icon';
import { InfoPanel } from '@/core/components/Misc';
import { AppBar, Screen, useBottomPadding } from '@/core/components/Screen';
import { Sheet } from '@/core/components/Sheet';
import { Text } from '@/core/components/Text';
import { TextField } from '@/core/components/TextField';
import { showToast } from '@/core/components/Toast';
import { useTheme } from '@/core/theme/useTheme';
import {
  isProvisional,
  rangeLabel,
  thresholdSourceLabel,
  toleranceLabel,
  type ParameterSpec,
} from '@/features/monitoring/domain/qualitySpec';
import { parameterIcon } from '@/features/monitoring/presentation/widgets/qualityColors';

import { useActiveStandard, useStandardStore } from '../application/standardStore';

/**
 * The reference values every verdict is measured against — specification §9.
 *
 * §12 records that the researchers have still to approve these ranges, which
 * is why they are editable at all: the app has to be able to follow the
 * standard once it is agreed, without a new build.
 */
export function ThresholdsScreen() {
  const standard = useActiveStandard();
  const resetAll = useStandardStore((s) => s.resetAll);
  const save = useStandardStore((s) => s.save);
  const bottom = useBottomPadding(32);
  const [editing, setEditing] = useState<ParameterSpec | null>(null);

  const confirmResetAll = () => {
    Alert.alert(
      'Restore default values?',
      'Every parameter goes back to the range the app shipped with. Batches already assessed keep the results they were given.',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Restore', onPress: () => void resetAll() },
      ],
    );
  };

  return (
    <Screen>
      <AppBar
        title="Reference values"
        back
        actions={<IconButton icon="restart-alt" accessibilityLabel="Restore defaults" onPress={confirmResetAll} />}
      />
      <ScrollView contentContainerStyle={[styles.content, { paddingBottom: bottom }]}>
        <InfoPanel>
          A reading inside the accepted range passes. Outside it but inside the tolerance band raises
          a warning; beyond the tolerance band the batch is reported as outside the selected quality
          parameters.
        </InfoPanel>
        <View style={{ height: 18 }} />
        {standard.specs.map((spec) => (
          <View key={spec.parameter} style={{ marginBottom: 10 }}>
            <ThresholdTile spec={spec} onPress={() => setEditing(spec)} />
          </View>
        ))}
      </ScrollView>
      <ThresholdEditor
        spec={editing}
        onClose={() => setEditing(null)}
        onSave={(spec) => {
          setEditing(null);
          void save(spec);
        }}
      />
    </Screen>
  );
}

function ThresholdTile({ spec, onPress }: { spec: ParameterSpec; onPress: () => void }) {
  const { scheme } = useTheme();
  const edited = spec.source === 'operatorEdited';
  const tolerance = toleranceLabel(spec);
  const provisional = isProvisional(spec);

  return (
    <Card onPress={onPress}>
      <View style={styles.tile}>
        <Icon name={parameterIcon(spec.parameter)} size={20} color={scheme.onSurfaceVariant} />
        <View style={{ flex: 1 }}>
          <View style={styles.tileTitle}>
            <Text variant="titleSmall" weight="600" style={{ flex: 1 }}>
              {spec.label}
            </Text>
            {provisional ? (
              <Icon name="help-outline" size={16} color={scheme.error} accessibilityLabel="Awaiting researcher approval" />
            ) : (
              edited && <Icon name="edit" size={16} color={scheme.primary} accessibilityLabel="Edited on this device" />
            )}
          </View>
          <Text variant="bodySmall" style={{ marginTop: 4 }}>
            {spec.rated ? `Accepted ${rangeLabel(spec)}` : 'Recorded but not graded'}
          </Text>
          {tolerance != null && (
            <Text variant="labelSmall" color={scheme.onSurfaceVariant}>
              Tolerance {tolerance}
            </Text>
          )}
          <Text variant="labelSmall" color={provisional ? scheme.error : scheme.onSurfaceVariant} style={{ marginTop: 2 }}>
            {thresholdSourceLabel(spec.source)}
          </Text>
        </View>
        <Icon name="chevron-right" size={24} color={scheme.outline} />
      </View>
    </Card>
  );
}

function ThresholdEditor({
  spec,
  onClose,
  onSave,
}: {
  spec: ParameterSpec | null;
  onClose: () => void;
  onSave: (spec: ParameterSpec) => void;
}) {
  return (
    <Sheet visible={spec != null} onClose={onClose} scroll>
      {spec && <EditorBody key={spec.parameter} spec={spec} onClose={onClose} onSave={onSave} />}
    </Sheet>
  );
}

const asText = (value: number | null | undefined) => (value == null ? '' : String(value));

function EditorBody({
  spec,
  onClose,
  onSave,
}: {
  spec: ParameterSpec;
  onClose: () => void;
  onSave: (spec: ParameterSpec) => void;
}) {
  const { scheme } = useTheme();
  const reset = useStandardStore((s) => s.reset);
  const [min, setMin] = useState(asText(spec.min));
  const [max, setMax] = useState(asText(spec.max));
  const [warnMin, setWarnMin] = useState(asText(spec.warnMin));
  const [warnMax, setWarnMax] = useState(asText(spec.warnMax));
  const [rated, setRated] = useState(spec.rated);
  const [errors, setErrors] = useState<Record<string, string | null>>({});
  const unit = spec.unit.length === 0 ? '' : ` (${spec.unit})`;

  const parse = (text: string): number | null => {
    const trimmed = text.trim();
    if (trimmed.length === 0) return null;
    const value = Number(trimmed);
    return Number.isFinite(value) ? value : null;
  };

  const validate = (text: string) =>
    text.trim().length > 0 && parse(text) == null ? 'Enter a number' : null;

  const submit = () => {
    const nextErrors = {
      min: validate(min),
      max: validate(max),
      warnMin: validate(warnMin),
      warnMax: validate(warnMax),
    };
    setErrors(nextErrors);
    if (Object.values(nextErrors).some((e) => e != null)) return;

    const minValue = parse(min);
    const maxValue = parse(max);
    if (minValue != null && maxValue != null && minValue > maxValue) {
      showToast('The minimum has to be below the maximum.');
      return;
    }

    onSave({
      ...spec,
      min: rated ? minValue : null,
      max: rated ? maxValue : null,
      warnMin: rated ? parse(warnMin) : null,
      warnMax: rated ? parse(warnMax) : null,
      rated,
      source: 'operatorEdited',
    });
  };

  return (
    <View style={styles.editor}>
      <Text variant="titleLarge" weight="700">
        {spec.label}
      </Text>
      <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={{ marginTop: 4 }}>
        Leave a field empty for no limit on that side.
      </Text>

      <View style={styles.switchRow}>
        <View style={{ flex: 1 }}>
          <Text variant="bodyLarge">Grade this parameter</Text>
          <Text variant="bodySmall" color={scheme.onSurfaceVariant}>
            Off records the reading without giving it a verdict
          </Text>
        </View>
        <Switch
          value={rated}
          onValueChange={setRated}
          trackColor={{ true: scheme.primary, false: scheme.surfaceContainerHighest }}
          thumbColor={scheme.surface}
        />
      </View>

      {rated && (
        <>
          <Text variant="labelSmall" color={scheme.primary} letterSpacing={0.8} style={{ marginTop: 12 }}>
            ACCEPTED RANGE
          </Text>
          <View style={styles.fieldRow}>
            <TextField
              label={`Minimum${unit}`}
              value={min}
              onChangeText={setMin}
              keyboardType="decimal-pad"
              dense
              errorText={errors.min}
              style={{ flex: 1 }}
            />
            <TextField
              label={`Maximum${unit}`}
              value={max}
              onChangeText={setMax}
              keyboardType="decimal-pad"
              dense
              errorText={errors.max}
              style={{ flex: 1 }}
            />
          </View>

          <Text variant="labelSmall" color={scheme.primary} letterSpacing={0.8} style={{ marginTop: 20 }}>
            TOLERANCE BAND
          </Text>
          <Text variant="bodySmall" color={scheme.onSurfaceVariant} style={{ marginTop: 4 }}>
            Between the accepted range and these limits, a reading warns instead of failing.
          </Text>
          <View style={styles.fieldRow}>
            <TextField
              label="Lower tolerance"
              value={warnMin}
              onChangeText={setWarnMin}
              keyboardType="decimal-pad"
              dense
              errorText={errors.warnMin}
              style={{ flex: 1 }}
            />
            <TextField
              label="Upper tolerance"
              value={warnMax}
              onChangeText={setWarnMax}
              keyboardType="decimal-pad"
              dense
              errorText={errors.warnMax}
              style={{ flex: 1 }}
            />
          </View>
        </>
      )}

      <View style={styles.actions}>
        <Button
          variant="text"
          label="Restore default"
          onPress={() => {
            void reset(spec.parameter);
            onClose();
          }}
        />
        <View style={{ flex: 1 }} />
        <Button label="Save" onPress={submit} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 16, paddingTop: 12 },
  tile: { flexDirection: 'row', alignItems: 'center', gap: 14, padding: 16 },
  tileTitle: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  editor: { paddingHorizontal: 20, paddingBottom: 8 },
  switchRow: { flexDirection: 'row', alignItems: 'center', gap: 12, marginTop: 20 },
  fieldRow: { flexDirection: 'row', gap: 12, marginTop: 8 },
  actions: { flexDirection: 'row', alignItems: 'center', marginTop: 24 },
});
