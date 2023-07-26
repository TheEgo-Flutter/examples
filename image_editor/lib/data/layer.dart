import 'package:flutter/material.dart';
import 'package:image_editor/data/image_item.dart';

/// Layer class with some common properties
class Layer {
  late Offset offset;
  late double rotation, scale, opacity;

  Layer({
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

/// Attributes used by [BackgroundLayer]
class BackgroundLayerData extends Layer {
  ImageItem file;

  BackgroundLayerData({
    required this.file,
  }) : super(offset: Offset.zero);
}

/// Attributes used by [BackgroundBlurLayer]
class BackgroundBlurLayerData extends Layer {
  Color color;
  double radius;

  BackgroundBlurLayerData({
    required this.color,
    required this.radius,
    Offset? offset,
    double? opacity,
    double? rotation,
    double? scale,
  }) : super(
          offset: offset,
          opacity: opacity,
          rotation: rotation,
          scale: scale,
        );
}

class ObjectLayer extends Layer {
  late double size;

  ObjectLayer({
    Offset? offset,
    double? opacity,
    double? rotation,
    double? scale,
    double? size,
  })  : size = size ?? 64,
        super(
          offset: offset,
          opacity: opacity,
          rotation: rotation,
          scale: scale,
        );
}

/// Attributes used by [StickerLayer]
class StickerLayerData extends ObjectLayer {
  String sticker;

  StickerLayerData({
    this.sticker = '',
    Offset? offset,
    double? opacity,
    double? size,
    double? rotation,
    double? scale,
  }) : super(
          offset: offset,
          opacity: opacity,
          rotation: rotation,
          scale: scale,
          size: size,
        );
}

/// Attributes used by [ImageLayer]
class ImageLayerData extends ObjectLayer {
  ImageItem image;

  ImageLayerData({
    required this.image,
    Offset? offset,
    double? opacity,
    double? size,
    double? rotation,
    double? scale,
  }) : super(
          offset: offset,
          opacity: opacity,
          rotation: rotation,
          scale: scale,
          size: size,
        );
}

/// Attributes used by [TextLayer]
class TextLayerData extends ObjectLayer {
  String text;

  Color color, background;
  int backgroundOpacity;
  TextAlign align;

  TextLayerData({
    required this.text,
    this.color = Colors.white,
    this.background = Colors.transparent,
    this.backgroundOpacity = 1,
    this.align = TextAlign.left,
    Offset? offset,
    double? opacity,
    double? size,
    double? rotation,
    double? scale,
  }) : super(
          offset: offset,
          opacity: opacity,
          rotation: rotation,
          scale: scale,
          size: size,
        );
}
