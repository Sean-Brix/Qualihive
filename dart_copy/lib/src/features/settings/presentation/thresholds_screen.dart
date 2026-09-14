import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../monitoring/domain/quality_spec.dart';
import '../../monitoring/presentation/widgets/quality_colors.dart';
import '../application/settings_providers.dart';

/// The reference values every verdict is measured against — specification §9.
///
/// §12 records that the researchers have still to approve these ranges, which
/// is why they are editable at all: the app has to be able to follow the
/// standard once it is agreed, without a new build.
class ThresholdsScreen extends ConsumerWidget {
  const ThresholdsScreen({super.key});

  static const String segment = 'reference-values';
  static const String name = 'thresholds';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final standard = ref.watch(activeStandardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reference values'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Restore defaults',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => _confirmResetAll(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.info_outline, size: 18, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A reading inside the accepted range passes. Outside it but '
                    'inside the tolerance band raises a warning; beyond the '
                    'tolerance band the batch is reported as outside the '
                    'selected quality parameters.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final spec in standard.specs) ...<Widget>[
            _ThresholdTile(spec: spec),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmResetAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore default values?'),
        content: const Text(
          'Every parameter goes back to the range the app shipped with. '
          'Batches already assessed keep the results they were given.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(thresholdControllerProvider.notifier).resetAll();
    }
  }
}

class _ThresholdTile extends ConsumerWidget {
  const _ThresholdTile({required this.spec});

  final ParameterSpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final edited = spec.source == ThresholdSource.operatorEdited;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _edit(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(
                spec.parameter.icon,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            spec.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (spec.isProvisional)
                          Tooltip(
                            message: 'Awaiting researcher approval',
                            child: Icon(
                              Icons.help_outline,
                              size: 16,
                              color: scheme.error,
                            ),
                          )
                        else if (edited)
                          Tooltip(
                            message: 'Edited on this device',
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: scheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spec.rated
                          ? 'Accepted ${spec.rangeLabel}'
                          : 'Recorded but not graded',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (spec.toleranceLabel case final tolerance?)
                      Text(
                        'Tolerance $tolerance',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      spec.source.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: spec.isProvisional
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<ParameterSpec>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _ThresholdEditor(spec: spec),
      ),
    );

    if (result != null) {
      await ref.read(thresholdControllerProvider.notifier).save(result);
    }
  }
}

class _ThresholdEditor extends ConsumerStatefulWidget {
  const _ThresholdEditor({required this.spec});

  final ParameterSpec spec;

  @override
  ConsumerState<_ThresholdEditor> createState() => _ThresholdEditorState();
}

class _ThresholdEditorState extends ConsumerState<_ThresholdEditor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _min = _controllerFor(widget.spec.min);
  late final TextEditingController _max = _controllerFor(widget.spec.max);
  late final TextEditingController _warnMin =
      _controllerFor(widget.spec.warnMin);
  late final TextEditingController _warnMax =
      _controllerFor(widget.spec.warnMax);
  late bool _rated = widget.spec.rated;

  static TextEditingController _controllerFor(double? value) =>
      TextEditingController(text: value == null ? '' : '$value');

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _warnMin.dispose();
    _warnMax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unit = widget.spec.unit.isEmpty ? '' : ' (${widget.spec.unit})';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.spec.label,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Leave a field empty for no limit on that side.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _rated,
                onChanged: (value) => setState(() => _rated = value),
                title: const Text('Grade this parameter'),
                subtitle: const Text(
                  'Off records the reading without giving it a verdict',
                ),
              ),
              if (_rated) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  'ACCEPTED RANGE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _NumberField(
                        controller: _min,
                        label: 'Minimum$unit',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberField(
                        controller: _max,
                        label: 'Maximum$unit',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'TOLERANCE BAND',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Between the accepted range and these limits, a reading '
                  'warns instead of failing.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _NumberField(
                        controller: _warnMin,
                        label: 'Lower tolerance',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberField(
                        controller: _warnMax,
                        label: 'Upper tolerance',
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(thresholdControllerProvider.notifier)
                          .reset(widget.spec.parameter);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Restore default'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final min = _parse(_min);
    final max = _parse(_max);

    if (min != null && max != null && min > max) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The minimum has to be below the maximum.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      ParameterSpec(
        parameter: widget.spec.parameter,
        label: widget.spec.label,
        shortLabel: widget.spec.shortLabel,
        unit: widget.spec.unit,
        min: _rated ? min : null,
        max: _rated ? max : null,
        warnMin: _rated ? _parse(_warnMin) : null,
        warnMax: _rated ? _parse(_warnMax) : null,
        rated: _rated,
        decimals: widget.spec.decimals,
        source: ThresholdSource.operatorEdited,
        note: widget.spec.note,
      ),
    );
  }

  static double? _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim());
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) return null;
        return double.tryParse(text) == null ? 'Enter a number' : null;
      },
    );
  }
}
