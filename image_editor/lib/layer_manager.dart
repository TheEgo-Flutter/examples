import 'package:flutter/widgets.dart';

enum LayerType { sticker, text, drawing, background, frame }

class LayerItem {
  final Key key;
  final LayerType type;
  final Widget widget;
  final Offset position;
  final Size size;

  LayerItem(
    this.key, {
    required this.type,
    required this.widget,
    required this.position,
    required this.size,
  });
}

class LayerManager {
  List<LayerItem> layers = [];
  List<LayerItem> undoLayers = [];
  List<LayerItem> removedLayers = [];

  void addLayer(LayerItem layer) {
    layers.add(layer);
  }

  void removeLayer(LayerItem layer) {
    int index = layers.indexWhere((item) => item.widget == layer.widget);
    if (index >= 0) {
      layers.removeAt(index);
      removedLayers.add(layer);
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
