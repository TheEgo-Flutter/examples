import 'package:flutter/material.dart';

/// Layer class with some common properties
class Layer {
  final UniqueKey key;
  late Offset offset;
  late double rotation, scale, opacity;

  Layer({
    required this.key,
    Offset? offset,
    double? opacity,
    double? rotation,
    double? scale,
  }) {
    this.offset = offset ?? const Offset(64, 64);
    this.opacity = opacity ?? 1;
    this.rotation = rotation ?? 0;
    this.scale = scale ?? 1;
  }
}

/// Attributes used by [BackgroundBlurLayer]
class BlurLayerData extends Layer {
  Color color;
  double radius;

  BlurLayerData({
    required this.color,
    required this.radius,
    Offset? offset,
    double? opacity,
    double? rotation,
    double? scale,
  }) : super(
          key: UniqueKey(),
          offset: offset,
          opacity: opacity,
          rotation: rotation,
          scale: scale,
        );
}

@Deprecated('Use DraggableResizable instead, need to refactor All Layers')
class LayerData extends Layer {
  Size size;
  final Widget object;

  LayerData({
    required super.key,
    required this.object,
    Offset? offset,
    double? opacity,
    double? rotation,
    double? scale,
    Size? size,
  })  : size = size ?? const Size(64, 64),
        super(
          offset: offset,
          opacity: opacity,
          rotation: rotation,
          scale: scale,
        );
}
