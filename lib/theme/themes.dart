import 'package:flutter/material.dart';

class _BaseTheme {
  ThemeData theme = ThemeData(
        textTheme: const TextTheme(
          // Title
          titleLarge: TextStyle(
            fontFamily: 'HeptaSlab',
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          // Display
          displayLarge: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          // Body
          bodyLarge: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          // Label
          labelLarge: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w200,
            letterSpacing: 0.15,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      );
}

class LightTheme extends _BaseTheme {
  @override
  ThemeData get theme => super.theme.copyWith(
        brightness: Brightness.light,
        textTheme: super.theme.textTheme,
        scaffoldBackgroundColor: Colors.white,
      );
}

class DarkTheme extends _BaseTheme {
  @override
  ThemeData get theme => super.theme.copyWith(
        brightness: Brightness.dark,
        textTheme: super.theme.textTheme,
        scaffoldBackgroundColor: Colors.black,
      );
}
