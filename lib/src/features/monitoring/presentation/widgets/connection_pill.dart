import 'package:flutter/material.dart';

import '../../data/transport/sensor_transport.dart';

/// Compact connection indicator for the app bar.
class ConnectionPill extends StatelessWidget {
  const ConnectionPill({super.key, required this.status, this.onTap});

  final TransportStatus status;
  final VoidCallback? onTap;

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
                  constraints: const BoxConstraints(maxWidth: 116),
                  child: Text(
                    status.label,
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

  Color _color(ColorScheme scheme) => switch (status.state) {
    TransportState.connected => const Color(0xFF2E7D32),
    TransportState.error || TransportState.unavailable => scheme.error,
    TransportState.scanning || TransportState.connecting => scheme.primary,
    TransportState.disconnected => scheme.onSurfaceVariant,
  };
}
