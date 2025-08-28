import 'package:flutter/material.dart';

import 'package:simple_logging/simple_logging.dart';

final _log = Logger('Theme', level: LogLevel.info);
// const _mainFont = 'Mallanna';
const _mainFont = 'AlibabaHealth';

// Color _addLightness(Color color, double offset) {
//   final hsl = HSLColor.fromColor(color);
//   final lighterHsl =
//       hsl.withLightness((hsl.lightness + offset).clamp(0.0, 1.0));
//   return lighterHsl.toColor();
// }

// Color _addSaturation(Color color, double offset) {
//   final hsl = HSLColor.fromColor(color);
//   final lighterHsl =
//       hsl.withSaturation((hsl.saturation + offset).clamp(0.0, 1.0));
//   return lighterHsl.toColor();
// }

double _lightness(Color color) {
  return HSLColor.fromColor(color).lightness;
}

double _saturation(Color color) {
  return HSLColor.fromColor(color).saturation;
}

double _hue(Color color) {
  return HSLColor.fromColor(color).hue;
}

void _dumpColor(Color color, String name) {
  final saturation = _saturation(color);
  final lightness = _lightness(color);
  final hue = _hue(color);
  _log.debug('');
  _log.debug('====== Dump Color: $name: ======');
  _log.debug('  red       : ${color.red}');
  _log.debug('  green     : ${color.green}');
  _log.debug('  blue      : ${color.blue}');
  _log.debug('  saturation: $saturation');
  _log.debug('  lightness : $lightness');
  _log.debug('  hue       : $hue');
}

const lightParameters = _ColorParameters(
  primary: _ColorParameter(lightness: 0.5, saturation: 0.99),
  onPrimary: _ColorParameter(lightness: 0.99, saturation: 0.01),
  secondary: _ColorParameter(lightness: 0.9, saturation: 0.9),
  onSecondary: _ColorParameter(lightness: 0.5, saturation: 0.95),
  background: _ColorParameter(lightness: 0.999, saturation: 0.0),
  highlight: _ColorParameter(lightness: 0.7, saturation: 0.1),
  hover: _ColorParameter(lightness: 0.8, saturation: 0.1),
);

const darkParameters = _ColorParameters(
  primary: _ColorParameter(lightness: 0.5, saturation: 0.99),
  onPrimary: _ColorParameter(lightness: 0.99, saturation: 0.01),
  secondary: _ColorParameter(lightness: 0.9, saturation: 0.9),
  onSecondary: _ColorParameter(lightness: 0.5, saturation: 0.95),
  background: _ColorParameter(lightness: 0.001, saturation: 0.0),
  highlight: _ColorParameter(lightness: 0.7, saturation: 0.1),
  hover: _ColorParameter(lightness: 0.8, saturation: 0.1),
);

// const darkParameters = _ColorParameters(
//   primary: _ColorParameter(lightness: 0.8, saturation: 0.6),
//   onPrimary: _ColorParameter(lightness: 0.5, saturation: 0.9),
//   secondary: _ColorParameter(lightness: 0.6, saturation: 0.9),
//   onSecondary: _ColorParameter(lightness: 0.3, saturation: 0.9),
//   background: _ColorParameter(lightness: 0.001, saturation: 0.0),
//   highlight: _ColorParameter(lightness: 0.3, saturation: 0.1),
//   hover: _ColorParameter(lightness: 0.2, saturation: 0.1),
// );

Color _generateColor(double hue, _ColorParameter param) {
  return HSLColor.fromAHSL(1.0, hue, param.saturation, param.lightness)
      .toColor();
}

bool isWarmColor(double hue) {
  return hue < 23.0 || hue > 265;
}

class AppTheme {
  static ThemeData getTheme(bool isDarkMode, Color primaryColor) {
    // Derive other colors based on the primary color
    // final luminance = primaryColor.computeLuminance();
    // final luminance = _lightness(primaryColor);
    // final saturation = _saturation(primaryColor);
    // final lightness = _lightness(primaryColor);
    // final isLight = luminance > 0.5;
    // Color accentColor = isLight ? _adjustLightness(primaryColor, 0.2) : _adjustLightness(primaryColor, 1.8);
    // double primaryThreshold = 0.6;
    // double secondaryThreshold = 0.1;
    final param = isDarkMode ? darkParameters : lightParameters;
    final hue = HSVColor.fromColor(primaryColor).hue;
    // Color primary = HSLColor.fromAHSL(
    //         1.0, hue, param.primary.saturation, param.primary.lightness)
    //     .toColor();
    // Color onPrimary = HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
    // Color secondary = HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
    // Color onSecondary = HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
    Color tertiary;
    Color background = _generateColor(hue, param.background);
    // if (saturation > 0.5) {
    //   double offset = saturation > 0.75 ? secondaryThreshold * -1 : secondaryThreshold;
    //   onPrimary = _addSaturation(primaryColor, primaryThreshold * -1);
    //     secondary = _addSaturation(primaryColor, offset);
    //     onSecondary = _addSaturation(onPrimary, offset);
    // } else {
    //   double offset = saturation > 0.25 ? secondaryThreshold * -1 : secondaryThreshold;
    //   onPrimary = _addSaturation(primaryColor, primaryThreshold);
    //     secondary = _addSaturation(primaryColor, offset);
    //     onSecondary = _addSaturation(onPrimary, offset);
    // }
    // if (lightness > 0.5) {
    //   double offset = lightness > 0.75 ? secondaryThreshold * -1 : secondaryThreshold;
    //   onPrimary = _addLightness(onPrimary, primaryThreshold * -1);
    //     secondary = _addLightness(secondary, offset);
    //     onSecondary = _addLightness(onSecondary, offset);
    // } else {
    //   double offset = saturation > 0.25 ? secondaryThreshold * -1 : secondaryThreshold;
    //   onPrimary = _addLightness(onPrimary, primaryThreshold);
    //     secondary = _addLightness(secondary, offset);
    //     onSecondary = _addLightness(onSecondary, offset);
    // }
    // _dumpColor(primary, 'primary');
    // _dumpColor(onPrimary, 'onPrimary');
    // _dumpColor(secondary, 'secondary');
    // _dumpColor(onSecondary, 'onSecondary');
    // if (luminance > 0.5) {
    //   double offset = luminance > 0.75 ? secondaryThreshold + 1 : secondaryThreshold -1;
    //   onPrimary = primaryColor.withOpacity(1 - primaryThreshold);
    //     secondary = primaryColor.withOpacity(offset);
    //     onSecondary = onPrimary.withOpacity(offset);
    // } else {
    //   double offset = luminance > 0.25 ? secondaryThreshold * -1 : secondaryThreshold;
    //   onPrimary = primaryColor.withOpacity(1 - primaryThreshold);
    //     secondary = primaryColor.withOpacity(offset);
    //     onSecondary = onPrimary.withOpacity(offset);
    // }

    // Define the range for pink or similar colors
    // const double pinkThreshold = 0.1; // Adjust this threshold as needed
    // bool isCloseToPink = (primaryColor.red - Colors.pink.red).abs() / 255.0 <
    //         pinkThreshold &&
    //     (primaryColor.green - Colors.pink.green).abs() / 255.0 <
    //         pinkThreshold &&
    //     (primaryColor.blue - Colors.pink.blue).abs() / 255.0 < pinkThreshold;
    if (isWarmColor(hue)) {
      tertiary = isDarkMode ? Colors.white : Colors.black;
    } else {
      tertiary = Colors.pinkAccent;
    }
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: _generateColor(hue, param.primary),
      onPrimary: _generateColor(hue, param.onPrimary),
      secondary: _generateColor(hue, param.secondary),
      onSecondary: _generateColor(hue, param.onSecondary),
      tertiary: tertiary,
      error: Colors.red,
      onError: Colors.white,
      // primaryColorLight: primaryColor.withOpacity(0.5),
      // secondary: primaryColor.withAlpha(180),
      // error: Colors.redAccent, // Assign errorColor through ColorScheme
    );
    _log.debug('DarkMode: $isDarkMode');
    _dumpColor(colorScheme.primary, 'primary');
    _dumpColor(colorScheme.onPrimary, 'onPrimary');
    _dumpColor(colorScheme.secondary, 'secondary');
    _dumpColor(colorScheme.onSecondary, 'onSecondary');
    _dumpColor(colorScheme.tertiary, 'tertiary');
    _dumpColor(background, 'background');


    return ThemeData(
      fontFamily: _mainFont,
      // primaryColor: primaryColor,
      // primaryColorLight: primaryColor.withOpacity(0.5),
      // cardColor: primaryColor.withOpacity(0.15),
      // highlightColor: accentColor,
      // indicatorColor: isCloseToPink ? accentColor : Colors.pink,
      // canvasColor: background,
      // hoverColor: _generateColor(hue, param.hover),
      // highlightColor: _generateColor(hue, param.highlight),
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontFamily: _mainFont,
          color: colorScheme.onPrimary,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onPrimary, // Set the back icon color here
        ),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onPrimary, // Set the back icon color here
      ),
      cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: colorScheme.primary),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary),
        titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary),
        titleMedium: TextStyle(fontSize: 18, color: colorScheme.onPrimary),
        titleSmall: TextStyle(
            fontSize: 16, color: colorScheme.onPrimary.withOpacity(0.8)),
        bodyMedium: TextStyle(fontSize: 16, color: colorScheme.onPrimary),
        bodySmall: TextStyle(fontSize: 16, color: colorScheme.primary),
        labelSmall: TextStyle(fontSize: 10, color: colorScheme.onPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        labelStyle: TextStyle(color: colorScheme.primary),
      ),
      // switchTheme: SwitchThemeData(
      //   thumbColor: WidgetStateProperty.resolveWith((states) {
      //     if (states.contains(WidgetState.disabled)) {
      //       return Colors.grey;
      //     }
      //     return primaryColor;
      //   }),
      //   trackColor: WidgetStateProperty.resolveWith((states) {
      //     if (states.contains(WidgetState.disabled)) {
      //       return Colors.grey[300];
      //     }
      //     return primaryColor.withOpacity(0.5);
      //   }),
      //   overlayColor: WidgetStateProperty.resolveWith((states) {
      //     if (states.contains(WidgetState.hovered)) {
      //       return primaryColor.withOpacity(0.08);
      //     }
      //     if (states.contains(WidgetState.focused) || states.contains(WidgetState.pressed)) {
      //       return primaryColor.withOpacity(0.24);
      //     }
      //     return null;
      //   }),
      // ),
      // elevatedButtonTheme: ElevatedButtonThemeData(
      //   style: ElevatedButton.styleFrom(
      //     backgroundColor: primaryColor,
      //     foregroundColor: accentColor,
      //     padding: const EdgeInsets.symmetric(vertical: 16.0),
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(8.0),
      //     ),
      //   ),
      // ),
      // textButtonTheme: TextButtonThemeData(
      //   style: TextButton.styleFrom(
      //     foregroundColor: primaryColor,
      //     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      //     shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(8.0),
      //   ),
      //   ),
      // ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      // outlinedButtonTheme: OutlinedButtonThemeData(
      //   style: OutlinedButton.styleFrom(
      //     foregroundColor: primaryColor,
      //     padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      //     side: BorderSide(color: primaryColor),
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(8.0),
      //     ),
      //   ),
      // ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        )
    );
  }
}

class _ColorParameter {
  final double saturation;
  final double lightness;

  const _ColorParameter({
    required this.lightness,
    required this.saturation,
  });
}

class _ColorParameters {
  final _ColorParameter primary;
  final _ColorParameter onPrimary;
  final _ColorParameter secondary;
  final _ColorParameter onSecondary;
  final _ColorParameter background;
  final _ColorParameter highlight;
  final _ColorParameter hover;

  const _ColorParameters({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.highlight,
    required this.hover,
  });
}
