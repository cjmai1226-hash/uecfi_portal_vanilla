import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

export 'package:hugeicons/hugeicons.dart';

/// Centralized icon widget for the application.
/// Sets a default [strokeWidth] of 2.0 so icons appear bold and distinct.
class AppIcon extends StatelessWidget {
  final dynamic icon;
  final Color? color;
  final double? size;
  final double strokeWidth;

  const AppIcon({
    super.key,
    required this.icon,
    this.color,
    this.size,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return HugeIcon(
      icon: icon,
      color: effectiveColor,
      size: size,
      strokeWidth: strokeWidth,
    );
  }
}
