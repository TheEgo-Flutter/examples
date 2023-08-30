import 'package:flutter/widgets.dart';

import 'global.dart';

enum LayerType { sticker, text, drawing, image, background, frame }

LayerItem? selectedLayerItem;

class LayerItem {
  final Key key;
  final LayerType type;
  final dynamic object;
  final Rect rect;
  final double angle;

  bool get isScalable {
    return type == LayerType.sticker || type == LayerType.image;
  }

  bool get isDraggable {
    return type == LayerType.sticker || type == LayerType.image || type == LayerType.text;
  }

  bool get isRotatable {
    return type == LayerType.sticker || type == LayerType.image || type == LayerType.text;
  }

  bool get isObject {
    return type == LayerType.sticker || type == LayerType.text;
  }

  bool get ignorePoint {
    return type == LayerType.frame || type == LayerType.drawing || type == LayerType.background;
  }

  LayerItem(
    this.key, {
    required this.type,
    required this.object,
    Rect? rect,
    this.angle = 0,
  }) : rect = rect ?? Rect.fromCenter(center: cardBoxRect.center, width: 0, height: 0);

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
  List<LayerItem> undoLayers = [];
  List<LayerItem> removedLayers = [];
  LayerItem? _backgroundLayer;
  LayerItem? _frameLayer;
  LayerItem? _drawingLayer;
  List<LayerItem> _otherLayers = [];

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
      case LayerType.background:
      case LayerType.image:
        _backgroundLayer = item;
        break;
      case LayerType.frame:
        _frameLayer = item;
        break;
      case LayerType.drawing:
        _drawingLayer = item;
        break;
      case LayerType.text:
      case LayerType.sticker:
        _otherLayers.add(item);
        break;
    }
  }

  void moveLayerToFront(LayerItem layer) {
    int index = _otherLayers.indexOf(layer);
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
      layer = _otherLayers.firstWhere((item) => item.key == key);
      _otherLayers.remove(layer);
    }
    if (layer != null) {
      _removeLayer(layer);
    }
  }

  void removeLayerByType(LayerType type) {
    LayerItem? layer;
    switch (type) {
      case LayerType.image:
      case LayerType.background:
        layer = _backgroundLayer;
        _backgroundLayer = null;
        break;
      case LayerType.frame:
        layer = _frameLayer;
        _frameLayer = null;
        break;
      case LayerType.drawing:
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

  void undo() {
    if (removedLayers.isNotEmpty) {
      layers.add(removedLayers.removeLast());
    } else if (layers.isNotEmpty) {
      undoLayers.add(layers.removeLast());
    }
  }

  void redo() {
    if (undoLayers.isNotEmpty) {
      layers.add(undoLayers.removeLast());
    }
  }
}
