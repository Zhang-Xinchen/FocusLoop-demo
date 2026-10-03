import 'package:flutter/material.dart';

/// Terminal-style segmented progress bar, inspired by Linux console
/// tools (apt / pacman / rsync): a row of solid blocks that fill from
/// left to right, plus an optional percentage readout.
class LinuxProgressBar extends StatelessWidget {
  const LinuxProgressBar({
    super.key,
    required this.value,
    this.height = 14,
    this.segments = 24,
    this.showPercent = false,
    this.color,
  });

  /// Progress in the range 0..1.
  final double value;
  final double height;
  final int segments;
  final bool showPercent;
  final Color? color;

  static const _fill = Color(0xFF33D17A);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = isDark ? const Color(0xFF2D333B) : const Color(0xFFE3E6E8);
    final fill = color ?? _fill;
    final clamped = value.clamp(0.0, 1.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 2.0;
              final blockWidth =
                  (constraints.maxWidth - gap * (segments - 1)) / segments;
              final filled = (clamped * segments).round();
              return SizedBox(
                height: height,
                child: Row(
                  children: [
                    for (var i = 0; i < segments; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          right: i == segments - 1 ? 0 : gap,
                        ),
                        child: Container(
                          width: blockWidth,
                          height: height,
                          decoration: BoxDecoration(
                            color: i < filled ? fill : track,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        if (showPercent) ...[
          const SizedBox(width: 8),
          Text(
            '${(clamped * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}
