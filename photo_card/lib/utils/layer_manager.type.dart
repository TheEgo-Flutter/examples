part of 'layer_manager.dart';

sealed class LayerType {
  final Background? background;
  final bool isScalable;
  final bool isDraggable;
  final bool isRotatable;
  final bool isObject;
  final bool ignorePoint;

  const LayerType({
    this.background,
    required this.isScalable,
    required this.isDraggable,
    required this.isRotatable,
    required this.isObject,
    required this.ignorePoint,
  });
}

class StickerType extends LayerType {
  StickerType()
      : super(
          isScalable: true,
          isDraggable: true,
          isRotatable: true,
          isObject: true,
          ignorePoint: false,
        );
}

class TextType extends LayerType {
  TextType()
      : super(
          isScalable: false,
          isDraggable: true,
          isRotatable: true,
          isObject: true,
          ignorePoint: false,
        );
}

class DrawingType extends LayerType {
  DrawingType()
      : super(
          isScalable: false,
          isDraggable: false,
          isRotatable: false,
          isObject: false,
          ignorePoint: true,
        );
}

enum Background { gallery, image, color }

class BackgroundType extends LayerType {
  const BackgroundType()
      : super(
          isScalable: false,
          isDraggable: false,
          isRotatable: false,
          isObject: false,
          ignorePoint: true,
        );
  const BackgroundType.gallery()
      : super(
          background: Background.gallery,
          isScalable: true,
          isDraggable: true,
          isRotatable: true,
          isObject: false,
          ignorePoint: false,
        );
  const BackgroundType.image()
      : super(
          background: Background.image,
          isScalable: false,
          isDraggable: false,
          isRotatable: false,
          isObject: false,
          ignorePoint: true,
        );
  const BackgroundType.color()
      : super(
          background: Background.color,
          isScalable: false,
          isDraggable: false,
          isRotatable: false,
          isObject: false,
          ignorePoint: true,
        );
}

class FrameType extends LayerType {
  FrameType()
      : super(
          isScalable: false,
          isDraggable: false,
          isRotatable: false,
          isObject: false,
          ignorePoint: true,
        );
}
