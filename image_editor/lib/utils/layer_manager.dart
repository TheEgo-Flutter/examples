import 'package:flutter/widgets.dart';

import 'global.rect.dart';

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
          isScalable: true,
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

class LayerItem {
  final Key key;
  final LayerType type;
  final dynamic object;
  final Rect rect;
  final double angle;

  LayerItem(
    this.key, {
    required this.type,
    required this.object,
    Rect? rect,
    this.angle = 0,
  }) : rect = rect ?? Rect.fromCenter(center: GlobalRect().cardRect.center, width: 0, height: 0);

  LayerItem copyWith({
    Rect? rect,
    double? angle,
    dynamic object,
  }) {
    return LayerItem(
      key,
      type: type,
      object: object ?? this.object,
      rect: rect ?? this.rect,
      angle: angle ?? this.angle,
    );
  }

  @override
  String toString() {
    return "LayerItem(rect: $rect, angle: $angle, key: $key, type: $type, object: $object)";
  }
}

class LayerManager {
  static final LayerManager _singleton = LayerManager._internal();

  factory LayerManager() {
    return _singleton;
  }

  LayerItem? _backgroundLayer;
  LayerItem? _frameLayer;
  LayerItem? _drawingLayer;
  List<LayerItem> _otherLayers = [];

  LayerItem? selectedLayerItem;

  List<LayerItem> removedLayers = [];
  LayerManager._internal();
  List<LayerItem> get layers {
    List<LayerItem> layers = [];
    if (_backgroundLayer != null) {
      layers.add(_backgroundLayer!);
    }
    if (_frameLayer != null) {
      layers.add(_frameLayer!);
    }
    layers.addAll(_otherLayers);
    if (_drawingLayer != null) {
      layers.add(_drawingLayer!);
    }
    return layers;
  }

  void addLayer(LayerItem item) {
    switch (item.type) {
      case BackgroundType():
        _backgroundLayer = item;
        break;
      case FrameType():
        _frameLayer = item;
        break;
      case DrawingType():
        _drawingLayer = item;
        break;
      case TextType():
      case StickerType():
        _otherLayers.add(item);
        break;
    }
  }

  void swap(LayerItem layer) {
    int index = _otherLayers.indexWhere((item) => item.key == layer.key);
    if (index != -1) {
      _otherLayers.removeAt(index);
      _otherLayers.add(layer);
    }
  }

  void _removeLayer(LayerItem layer) {
    int index = layers.indexWhere((item) => item.key == layer.key);
    if (index != -1) {
      removedLayers.add(layers[index]);
      layers.removeAt(index);
    }
  }

  void removeLayerByKey(Key key) {
    LayerItem? layer;
    if (_backgroundLayer?.key == key) {
      layer = _backgroundLayer;
      _backgroundLayer = null;
    } else if (_frameLayer?.key == key) {
      layer = _frameLayer;
      _frameLayer = null;
    } else if (_drawingLayer?.key == key) {
      layer = _drawingLayer;
      _drawingLayer = null;
    } else {
      layer = _otherLayers.where((item) => item.key == key).firstOrNull;
      _otherLayers.remove(layer);
    }
    if (layer != null) {
      _removeLayer(layer);
    }
  }

  void removeLayerByType(LayerType type) {
    LayerItem? layer;
    switch (type) {
      case BackgroundType():
        layer = _backgroundLayer;
        _backgroundLayer = null;
        break;
      case FrameType():
        layer = _frameLayer;
        _frameLayer = null;
        break;
      case DrawingType():
        layer = _drawingLayer;
        _drawingLayer = null;
        break;
      default:
        break;
    }
    if (layer != null) {
      _removeLayer(layer);
    }
  }

  void updateLayer(LayerItem layer) {
    int index = _otherLayers.indexWhere((item) => item.key == layer.key);
    if (index != -1) {
      _otherLayers[index] = layer;
    }
  }
}
