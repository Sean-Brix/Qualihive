import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/qualihive_logo.dart';
import '../application/auth_providers.dart';
import '../domain/account.dart';

/// Sign in, or create the first local account.
///
/// The system is offline, so there is no password-recovery flow to offer:
/// nothing off the device can verify who the beekeeper is.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  static const String path = '/sign-in';
  static const String name = 'sign-in';

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _farmName = TextEditingController();

  bool _creatingAccount = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  /// Null until the account count is known; the form opens on Create account
  /// when the device has none yet.
  bool _modeChosen = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _displayName.dispose();
    _farmName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAccounts = ref.watch(hasAnyAccountProvider).value;
    if (hasAccounts != null && !_modeChosen) {
      _modeChosen = true;
      _creatingAccount = !hasAccounts;
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 840) {
              return Row(
                children: <Widget>[
                  const Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 10, 20),
                      child: _AuthHero(),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(42, 36, 42, 36),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _buildFormPanel(context),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 230, child: _AuthHero()),
                      const SizedBox(height: 16),
                      _buildFormPanel(context),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormPanel(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF17352E).withValues(
              alpha: theme.brightness == Brightness.dark ? 0.22 : 0.06,
            ),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const QualihiveLogo(size: 34),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Offline & private',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _creatingAccount ? 'Set up your workspace' : 'Welcome back',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 7),
            Text(
              _creatingAccount
                  ? 'Create the local account that will own this device\'s batch records.'
                  : 'Sign in to continue monitoring filtration quality.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 26),
            TextFormField(
              controller: _username,
              autocorrect: false,
              autofillHints: const <String>[AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter your username' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: <String>[
                _creatingAccount
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              textInputAction: _creatingAccount
                  ? TextInputAction.next
                  : TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                helperText: _creatingAccount
                    ? '8+ characters, with a letter and a number'
                    : null,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                ),
              ),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Enter your password' : null,
            ),
            if (_creatingAccount) ...<Widget>[
              const SizedBox(height: 14),
              TextFormField(
                controller: _displayName,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _farmName,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Farm name (optional)',
                  prefixIcon: Icon(Icons.agriculture_outlined),
                ),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: scheme.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _creatingAccount
                          ? Icons.add_circle_outline_rounded
                          : Icons.arrow_forward_rounded,
                    ),
              label: Text(_creatingAccount ? 'Create account' : 'Sign in'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _creatingAccount = !_creatingAccount;
                      _error = null;
                    }),
              child: Text(
                _creatingAccount
                    ? 'I already have an account'
                    : 'Create a new account',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Accounts and records stay on this device. There is no '
                    'cloud backup or password recovery.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final controller = ref.read(sessionControllerProvider.notifier);

    try {
      if (_creatingAccount) {
        await controller.signUp(
          username: _username.text,
          password: _password.text,
          displayName: _displayName.text,
          farmName: _farmName.text,
        );
      } else {
        await controller.signIn(
          username: _username.text,
          password: _password.text,
        );
      }

      // The controller swallows failures into its own AsyncError, so the
      // result has to be read back rather than caught here.
      final state = ref.read(sessionControllerProvider);
      final error = state.error;
      if (error != null) throw error;
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object catch (error) {
      if (mounted) setState(() => _error = 'Something went wrong: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero();

  static const String _asset = 'assets/illustrations/honey_filter_hero.png';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Semantics(
            image: true,
            label: 'Honey passing through a precision filtration mesh',
            child: Image.asset(
              _asset,
              fit: BoxFit.cover,
              alignment: const Alignment(0.28, 0),
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0x0011241E),
                  Color(0x1811241E),
                  Color(0xE811241E),
                ],
                stops: <double>[0, 0.48, 1],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const QualihiveWordmark(size: 25),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Clear readings.\nConfident batches.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Honey filtration intelligence, entirely on your device.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
