import 'package:flutter/widgets.dart';

enum LayerType { sticker, text, drawing, background, frame }

class LayerItem {
  final Key key;
  final LayerType type;
  final dynamic object;
  final Offset position;
  final Size size;
  bool get isFixed {
    return type == LayerType.frame || type == LayerType.drawing;
  }

  LayerItem(
    this.key, {
    required this.type,
    required this.object,
    required this.position,
    required this.size,
  });

  LayerItem copyWith({
    Offset? position,
    Size? size,
    dynamic object,
  }) {
    return LayerItem(
      key,
      type: type,
      object: object ?? this.object,
      position: position ?? this.position,
      size: size ?? this.size,
    );
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
    if (_drawingLayer != null) {
      layers.add(_drawingLayer!);
    }
    layers.addAll(_otherLayers);
    return layers;
  }

  void addLayer(LayerItem item) {
    switch (item.type) {
      case LayerType.background:
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

  void removeLayer(LayerItem layer) {
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
      removeLayer(layer);
    }
  }

  /// Remove layer by type background, frame, drawing
  void removeLayerByType(LayerType type) {
    LayerItem? layer;
    switch (type) {
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
      removeLayer(layer);
    }
  }

  /// old Layer.object new object
  void updateLayer(LayerItem layer, dynamic object) {
    int index = layers.indexWhere((item) => item.object == layer.object);
    if (index >= 0) {
      layers[index] = layer.copyWith(object: object);
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
