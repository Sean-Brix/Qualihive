import 'package:flutter/material.dart';

import '../../data/transport/sensor_transport.dart';

/// Compact connection indicator for the app bar.
class ConnectionPill extends StatelessWidget {
  const ConnectionPill({
    super.key,
    required this.status,
    this.onTap,
    this.compact = false,
  });

  final TransportStatus status;
  final VoidCallback? onTap;

  /// Names the connection state rather than the device.
  ///
  /// A device name runs long — "Qualihive Simulator" alone is wider than the
  /// title it shares the app bar with — so screens that put something else in
  /// the title ask for the short form. The device name is still one tap away
  /// on the Device screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = _color(scheme);

    return Material(
      color: color.withValues(alpha: 0.09),
      shape: StadiumBorder(
        side: BorderSide(color: color.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (status.isBusy)
                  SizedBox.square(
                    dimension: 11,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                else
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 92 : 116),
                  child: Text(
                    _label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _label {
    if (!compact) return status.label;

    return switch (status.state) {
      TransportState.unavailable => 'No Bluetooth',
      TransportState.disconnected => 'Offline',
      TransportState.scanning => 'Scanning…',
      TransportState.connecting => 'Connecting…',
      TransportState.connected => 'Connected',
      TransportState.error => 'Error',
    };
  }

  Color _color(ColorScheme scheme) => switch (status.state) {
    TransportState.connected => const Color(0xFF2E7D32),
    TransportState.error || TransportState.unavailable => scheme.error,
    TransportState.scanning || TransportState.connecting => scheme.primary,
    TransportState.disconnected => scheme.onSurfaceVariant,
  };
}
