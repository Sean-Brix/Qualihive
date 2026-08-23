import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../application/auth_providers.dart';
import '../domain/account.dart';

/// Account details and password change — specification §9.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  static const String segment = 'profile';
  static const String name = 'profile';

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _farmName = TextEditingController();
  final TextEditingController _email = TextEditingController();

  bool _loaded = false;
  bool _dirty = false;

  @override
  void dispose() {
    _displayName.dispose();
    _farmName.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final account = ref.watch(sessionControllerProvider).value;

    if (account == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Seed the fields once, so a rebuild does not overwrite what is being typed.
    if (!_loaded) {
      _loaded = true;
      _displayName.text = account.displayName;
      _farmName.text = account.farmName ?? '';
      _email.text = account.email ?? '';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                CircleAvatar(
                  radius: 36,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    account.initials,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('@${account.username}', style: theme.textTheme.bodyMedium),
                Text(
                  'Joined ${DateFormat.yMMMd().format(account.createdAt)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _displayName,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _markDirty(),
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _farmName,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _markDirty(),
            decoration: const InputDecoration(
              labelText: 'Farm name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _markDirty(),
            decoration: const InputDecoration(
              labelText: 'Email (optional)',
              helperText: 'Stored on this device only; nothing is sent to it',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _dirty ? () => _save(account) : null,
            child: const Text('Save changes'),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _changePassword(account),
          ),
        ],
      ),
    );
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save(Account account) async {
    await ref.read(sessionControllerProvider.notifier).updateProfile(
          displayName: _displayName.text,
          farmName: _farmName.text,
          email: _email.text,
        );

    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated.')),
    );
  }

  Future<void> _changePassword(Account account) async {
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _PasswordSheet(),
      ),
    );

    if (result == null) return;

    try {
      await ref.read(sessionControllerProvider.notifier).changePassword(
            currentPassword: result.$1,
            newPassword: result.$2,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed.')),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _current = TextEditingController();
  final TextEditingController _next = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Change password',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _current,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value ?? '').isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _next,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  helperText: 'At least 8 characters, with a letter and a number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value ?? '').isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == _next.text ? null : 'The passwords do not match',
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  Navigator.of(context).pop((_current.text, _next.text));
                },
                child: const Text('Change password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
