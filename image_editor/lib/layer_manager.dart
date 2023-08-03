import 'package:flutter/widgets.dart';

class LayerManager {
  List<Widget> layers = [];
  List<Widget> undoLayers = [];
  List<Widget> removedLayers = [];

  void addLayer(Widget layer) {
    layers.add(layer);
  }

  void removeLayer(Widget layer) {
    int index = layers.indexOf(layer);
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
