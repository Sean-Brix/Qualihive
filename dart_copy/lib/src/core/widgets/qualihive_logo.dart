import 'package:flutter/material.dart';

/// The production Qualihive mark.
///
/// The generated symbol combines a honeycomb chamber, a droplet, a filter gate
/// and a subtle Q silhouette. Keeping it behind this widget gives every call
/// site the same clipping, semantics and image-quality settings.
class QualihiveLogo extends StatelessWidget {
  const QualihiveLogo({super.key, this.size = 32});

  static const String assetName = 'assets/branding/qualihive_app_icon.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Qualihive',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          assetName,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            color: Theme.of(context).colorScheme.primary,
            alignment: Alignment.center,
            child: Icon(
              Icons.water_drop_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
              size: size * 0.52,
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo plus live-text wordmark, for app bars and branded empty states.
class QualihiveWordmark extends StatelessWidget {
  const QualihiveWordmark({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.65,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        QualihiveLogo(size: size),
        SizedBox(width: size * 0.35),
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(text: 'Quali', style: style),
              TextSpan(
                text: 'hive',
                style: style?.copyWith(color: theme.colorScheme.secondary),
              ),
            ],
          ),
          semanticsLabel: 'Qualihive',
        ),
      ],
    );
  }
}
