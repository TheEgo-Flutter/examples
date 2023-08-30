import 'package:flutter/material.dart';

const background = Color(0xFF000000);
const canvas = Color(0xFFFFFFFF);
const box = Color.fromARGB(136, 0, 0, 0);
const label = Color(0xFFFFFFFF);
const accent = Color(0xFFD2F002);

CustomColors customColors = const CustomColors(
  background: background,
  canvas: canvas,
  box: box,
  label: label,
  accent: accent,
);

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  final Color? background;
  final Color? canvas;
  final Color? box;
  final Color? label;
  final Color? accent;

  const CustomColors({this.background, this.canvas, this.box, this.label, this.accent});

  @override
  CustomColors copyWith({
    Color? background,
    Color? canvas,
    Color? box,
    Color? label,
    Color? accent,
  }) {
    return CustomColors(
      background: background ?? this.background,
      canvas: canvas ?? this.canvas,
      box: box ?? this.box,
      label: label ?? this.label,
      accent: accent ?? this.accent,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      background: Color.lerp(background, other.background, t),
      canvas: Color.lerp(canvas, other.canvas, t),
      box: Color.lerp(box, other.box, t),
      label: Color.lerp(label, other.label, t),
      accent: Color.lerp(accent, other.accent, t),
    );
  }

  CustomColors harmonized(ColorScheme dynamic) {
    return copyWith();
  }
}
