import 'package:flutter/material.dart';

/// Windows 的微软雅黑只有常规(400)和粗体(700)两档字重，而 Android 的
/// Noto/Roboto 拥有完整字重阶梯。为避免同一 w500/w600 在两端渲染出
/// 不同粗细，这里把整套文本主题归一化到 400/700 两档。
TextTheme _normalizeWeights(TextTheme theme) {
  TextStyle? fix(TextStyle? style) {
    if (style == null) {
      return null;
    }
    final weight = style.fontWeight ?? FontWeight.w400;
    return style.copyWith(
      fontWeight:
          weight.index >= FontWeight.w500.index ? FontWeight.w700 : FontWeight.w400,
    );
  }

  return theme.copyWith(
    displayLarge: fix(theme.displayLarge),
    displayMedium: fix(theme.displayMedium),
    displaySmall: fix(theme.displaySmall),
    headlineLarge: fix(theme.headlineLarge),
    headlineMedium: fix(theme.headlineMedium),
    headlineSmall: fix(theme.headlineSmall),
    titleLarge: fix(theme.titleLarge),
    titleMedium: fix(theme.titleMedium),
    titleSmall: fix(theme.titleSmall),
    bodyLarge: fix(theme.bodyLarge),
    bodyMedium: fix(theme.bodyMedium),
    bodySmall: fix(theme.bodySmall),
    labelLarge: fix(theme.labelLarge),
    labelMedium: fix(theme.labelMedium),
    labelSmall: fix(theme.labelSmall),
  );
}

ThemeData buildAppTheme(Brightness brightness) {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A6FA5),
      brightness: brightness,
    ),
    useMaterial3: true,
  );
  return base.copyWith(textTheme: _normalizeWeights(base.textTheme));
}
