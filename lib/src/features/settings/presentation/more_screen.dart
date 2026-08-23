import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/profile_screen.dart';
import '../../monitoring/application/monitoring_providers.dart';
import '../../monitoring/presentation/device_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../reports/presentation/export_screen.dart';
import 'about_screen.dart';
import 'thresholds_screen.dart';

/// Everything that does not need a tab of its own.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static const String path = '/more';
  static const String name = 'more';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final account = ref.watch(sessionControllerProvider).value;
    final unread = ref.watch(unreadAlertCountProvider).value ?? 0;
    final status = ref.watch(transportStatusProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
        children: <Widget>[
          if (account != null) ...<Widget>[
            _ProfileCard(
              name: account.displayName,
              supporting: account.farmName ?? '@${account.username}',
              initials: account.initials,
              onTap: () => context.goNamed(ProfileScreen.name),
            ),
            const SizedBox(height: 24),
          ],
          _SettingsGroup(
            eyebrow: 'MONITORING',
            children: <Widget>[
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: unread == 0 ? 'No unread alerts' : '$unread unread',
                badgeCount: unread,
                onTap: () => context.goNamed(NotificationsScreen.name),
              ),
              _SettingsTile(
                icon: Icons.bluetooth_rounded,
                title: 'Machine connection',
                subtitle: status?.label ?? 'Disconnected',
                onTap: () => context.goNamed(DeviceScreen.name),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SettingsGroup(
            eyebrow: 'ASSESSMENT',
            children: <Widget>[
              _SettingsTile(
                icon: Icons.tune_rounded,
                title: 'Quality reference values',
                subtitle: 'Accepted ranges each parameter is graded on',
                onTap: () => context.goNamed(ThresholdsScreen.name),
              ),
              _SettingsTile(
                icon: Icons.ios_share_rounded,
                title: 'Export and reports',
                subtitle: 'PDF reports and CSV data',
                onTap: () => context.goNamed(ExportScreen.name),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SettingsGroup(
            eyebrow: 'APP',
            children: <Widget>[
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About Qualihive',
                subtitle: 'Project, sensors and system information',
                onTap: () => context.goNamed(AboutScreen.name),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: scheme.error.withValues(alpha: 0.25)),
            ),
            child: ListTile(
              onTap: () => _confirmSignOut(context, ref),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: scheme.error,
                  size: 21,
                ),
              ),
              title: Text('Sign out', style: TextStyle(color: scheme.error)),
              subtitle: const Text('Keep local records on this device'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Batch records stay on this device. You will need your password to '
          'sign back in.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(sessionControllerProvider.notifier).signOut();
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.supporting,
    required this.initials,
    required this.onTap,
  });

  final String name;
  final String supporting;
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[scheme.primaryContainer, scheme.surface],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 27,
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  child: Text(
                    initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(name, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        supporting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 13,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'LOCAL WORKSPACE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.65,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: scheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.eyebrow, required this.children});

  final String eyebrow;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 9),
          child: Text(
            eyebrow,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.secondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        ),
        Card(
          child: Column(
            children: <Widget>[
              for (var index = 0; index < children.length; index++) ...<Widget>[
                children[index],
                if (index < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 70,
                    color: scheme.outlineVariant.withValues(alpha: 0.75),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconWidget = Icon(icon, color: scheme.onPrimaryContainer, size: 21);

    return ListTile(
      onTap: onTap,
      minTileHeight: 76,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Center(
          child: badgeCount > 0
              ? Badge.count(count: badgeCount, child: iconWidget)
              : iconWidget,
        ),
      ),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 17,
        color: scheme.outline,
      ),
    );
  }
}
