import 'package:flutter/widgets.dart';

enum LayerType { sticker, text, drawing, background, frame }

class LayerItem {
  final Key key;
  final LayerType type;
  final Widget widget;
  final Offset position;
  final Size size;
  bool get isFixed {
    return type == LayerType.frame || type == LayerType.drawing;
  }

  LayerItem(
    this.key, {
    required this.type,
    required this.widget,
    required this.position,
    required this.size,
  });
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
    int index = layers.indexWhere((item) => item.widget == layer.widget);
    if (index >= 0) {
      layers.removeAt(index);
      removedLayers.add(layer);
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
