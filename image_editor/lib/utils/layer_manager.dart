import 'package:flutter/widgets.dart';

import 'global.rect.dart';

part 'layer_manager.item.dart';
part 'layer_manager.type.dart';

class LayerManager {
  static final LayerManager _singleton = LayerManager._internal();

  factory LayerManager() {
    return _singleton;
  }

  LayerItem? backgroundLayer;
  LayerItem? frameLayer;
  LayerItem? drawingLayer;
  List<LayerItem> objectLayers = [];

  LayerItem? selectedLayerItem;

  List<LayerItem> removedLayers = [];
  LayerManager._internal();
  List<LayerItem> get layers {
    List<LayerItem> layers = [];
    if (backgroundLayer != null) {
      layers.add(backgroundLayer!);
    }
    if (frameLayer != null) {
      layers.add(frameLayer!);
    }
    layers.addAll(objectLayers);
    if (drawingLayer != null) {
      layers.add(drawingLayer!);
    }
    return layers;
  }

  void addLayer(LayerItem item) {
    switch (item.type) {
      case BackgroundType():
        backgroundLayer = item;
        break;
      case FrameType():
        frameLayer = item;
        break;
      case DrawingType():
        drawingLayer = item;
        break;
      case TextType():
      case StickerType():
        objectLayers.add(item);
        break;
    }
  }

  void swap(LayerItem layer) {
    int index = objectLayers.indexWhere((item) => item.key == layer.key);
    if (index != -1) {
      objectLayers.removeAt(index);
      objectLayers.add(layer);
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
    if (backgroundLayer?.key == key) {
      layer = backgroundLayer;
      backgroundLayer = null;
    } else if (frameLayer?.key == key) {
      layer = frameLayer;
      frameLayer = null;
    } else if (drawingLayer?.key == key) {
      layer = drawingLayer;
      drawingLayer = null;
    } else {
      layer = objectLayers.where((item) => item.key == key).firstOrNull;
      objectLayers.remove(layer);
    }
    if (layer != null) {
      _removeLayer(layer);
    }
  }

  void removeLayerByType(LayerType type) {
    LayerItem? layer;
    switch (type) {
      case BackgroundType():
        layer = backgroundLayer;
        backgroundLayer = null;
        break;
      case FrameType():
        layer = frameLayer;
        frameLayer = null;
        break;
      case DrawingType():
        layer = drawingLayer;
        drawingLayer = null;
        break;
      default:
        break;
    }
    if (layer != null) {
      _removeLayer(layer);
    }
  }

  void updateLayer(LayerItem layer) {
    int index = objectLayers.indexWhere((item) => item.key == layer.key);
    if (index != -1) {
      objectLayers[index] = layer;
    }
  }
}
