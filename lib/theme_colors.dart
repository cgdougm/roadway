import 'package:flutter/material.dart';

class ThemeColorPalette extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    List<MapEntry<String, Color>> colors = [
      MapEntry('primary', colorScheme.primary),
      MapEntry('onPrimary', colorScheme.onPrimary),
      MapEntry('primaryContainer', colorScheme.primaryContainer),
      MapEntry('onPrimaryContainer', colorScheme.onPrimaryContainer),
      MapEntry('secondary', colorScheme.secondary),
      MapEntry('onSecondary', colorScheme.onSecondary),
      MapEntry('secondaryContainer', colorScheme.secondaryContainer),
      MapEntry('onSecondaryContainer', colorScheme.onSecondaryContainer),
      MapEntry('tertiary', colorScheme.tertiary),
      MapEntry('onTertiary', colorScheme.onTertiary),
      MapEntry('tertiaryContainer', colorScheme.tertiaryContainer),
      MapEntry('onTertiaryContainer', colorScheme.onTertiaryContainer),
      MapEntry('error', colorScheme.error),
      MapEntry('onError', colorScheme.onError),
      MapEntry('errorContainer', colorScheme.errorContainer),
      MapEntry('onErrorContainer', colorScheme.onErrorContainer),
      // MapEntry('background', colorScheme.background),
      // MapEntry('onBackground', colorScheme.onBackground),
      MapEntry('surface', colorScheme.surface),
      MapEntry('onSurface', colorScheme.onSurface),
      // MapEntry('surfaceVariant', colorScheme.surfaceVariant),
      MapEntry('onSurfaceVariant', colorScheme.onSurfaceVariant),
      MapEntry('outline', colorScheme.outline),
      MapEntry('outlineVariant', colorScheme.outlineVariant),
      MapEntry('shadow', colorScheme.shadow),
      MapEntry('scrim', colorScheme.scrim),
      MapEntry('inverseSurface', colorScheme.inverseSurface),
      MapEntry('onInverseSurface', colorScheme.onInverseSurface),
      MapEntry('inversePrimary', colorScheme.inversePrimary),
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: colors.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 25,
                    color: entry.value,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}