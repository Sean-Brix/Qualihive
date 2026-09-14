import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/qualihive_logo.dart';
import '../../monitoring/presentation/widgets/quality_colors.dart';
import '../application/settings_providers.dart';

/// System and project information — specification §9.
///
/// It also carries the scope statement of §12 in plain language, so anyone
/// reading a result knows what the app claims and what it does not.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const String segment = 'about';
  static const String name = 'about';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final standard = ref.watch(activeStandardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                const QualihiveLogo(size: 64),
                const SizedBox(height: 14),
                Text(
                  'Qualihive',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const _Section(
            title: 'What this app does',
            body: 'Qualihive is the companion application for an Arduino-based '
                'honey filtration machine with quality assessment. It connects '
                'to the machine over Bluetooth, receives sensor readings and '
                'machine status, interprets the readings against configured '
                'quality reference values, records each filtration session as '
                'a batch, and produces exportable assessment reports.',
          ),
          const _Section(
            title: 'What it does not do',
            body: 'The app assesses honey against the selected quality '
                'parameters. It does not establish authenticity or purity, and '
                'it does not replace laboratory testing. It monitors and '
                'records; it does not operate the machine.',
          ),
          const _Section(
            title: 'Offline by design',
            body: 'Accounts, batch records, readings and notifications are '
                'stored in a local database on this device. Nothing is sent to '
                'a server, which also means nothing is backed up: exporting a '
                'report or CSV is the only way to get data off the phone.',
          ),
          const SizedBox(height: 8),
          Text(
            'ACTIVE REFERENCE VALUES',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Column(
                children: <Widget>[
                  for (final spec in standard.specs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            spec.parameter.icon,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  spec.label,
                                  style: theme.textTheme.bodyMedium,
                                ),
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
                          Text(
                            spec.rangeLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _Section(
            title: 'Project',
            body: 'Arduino-Based Honey Filtration with Quality Assessment '
                'System for Honey Ko Bee Farm. The filtration machine handles '
                'the physical processing and sensing; this application handles '
                'presentation, assessment rules, batch history, alerts and '
                'reporting.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
