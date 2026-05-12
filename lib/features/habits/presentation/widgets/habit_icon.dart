import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:habit_dashboard/features/habits/domain/habit.dart';

class HabitIcon extends StatelessWidget {
  final Habit habit;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry padding;

  const HabitIcon({
    super.key,
    required this.habit,
    this.size = 42,
    this.iconSize = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 14,
    this.shape = BoxShape.rectangle,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? habit.color.withOpacity(0.14);
    final fg = foregroundColor ?? habit.color;
    final imageBytes = _decodeIconBytes(habit.customIconBase64);

    return Container(
      width: size,
      height: size,
      padding: imageBytes == null ? padding : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: bg,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageBytes == null
          ? Icon(habit.iconData, color: fg, size: iconSize)
          : Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              cacheWidth: (size * 3).round(),
              cacheHeight: (size * 3).round(),
              errorBuilder: (_, __, ___) => Icon(habit.iconData, color: fg, size: iconSize),
            ),
    );
  }

  Uint8List? _decodeIconBytes(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return null;
    try {
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }
}
