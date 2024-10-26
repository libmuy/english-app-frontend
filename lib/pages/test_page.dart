import 'package:flutter/material.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});
  List<Widget> showColors(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = {
      'primary': colorScheme.primary,
      'onPrimary': colorScheme.onPrimary,
      // 'primaryContainer': colorScheme.primaryContainer,
      // 'onPrimaryContainer': colorScheme.onPrimaryContainer,
      // 'primaryFixed': colorScheme.primaryFixed,
      // 'onPrimaryFixed': colorScheme.onPrimaryFixed,
      // 'primaryFixedDim': colorScheme.primaryFixedDim,
      // 'onPrimaryFixedVariant': colorScheme.onPrimaryFixedVariant,
      'secondary': colorScheme.secondary,
      'onSecondary': colorScheme.onSecondary,
      // 'secondaryContainer': colorScheme.secondaryContainer,
      // 'onSecondaryContainer': colorScheme.onSecondaryContainer,
      // 'secondaryFixed': colorScheme.secondaryFixed,
      // 'onSecondaryFixed': colorScheme.onSecondaryFixed,
      // 'secondaryFixedDim': colorScheme.secondaryFixedDim,
      // 'onSecondaryFixedVariant': colorScheme.onSecondaryFixedVariant,
      'tertiary': colorScheme.tertiary,
      // 'onTertiary': colorScheme.onTertiary,
      // 'tertiaryContainer': colorScheme.tertiaryContainer,
      // 'onTertiaryContainer': colorScheme.onTertiaryContainer,
      // 'tertiaryFixed': colorScheme.tertiaryFixed,
      // 'onTertiaryFixed': colorScheme.onTertiaryFixed,
      // 'tertiaryFixedDim': colorScheme.tertiaryFixedDim,
      // 'onTertiaryFixedVariant': colorScheme.onTertiaryFixedVariant,
      'error': colorScheme.error,
      'onError': colorScheme.onError,
      'errorContainer': colorScheme.errorContainer,
      'onErrorContainer': colorScheme.onErrorContainer,
      'outline': colorScheme.outline,
      'outlineVariant': colorScheme.outlineVariant,
    };

    return colors.keys.map((k) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              k,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 50,
              width: 200,
              color: colors[k],
            ),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test'),
      ),
      body: ListView(
        children: [
          ...showColors(context),
        ],
      ),
    );
  }
}
