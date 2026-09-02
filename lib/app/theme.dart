import 'package:flutter/material.dart';

ThemeData buildAppTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A6FA5),
      brightness: brightness,
    ),
    useMaterial3: true,
  );
}
