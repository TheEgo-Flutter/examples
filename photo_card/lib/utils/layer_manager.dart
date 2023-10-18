import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'layer_manager.item.dart';
part 'layer_manager.type.dart';

final layerManagerNotifierProvider = NotifierProvider<LayerManagerNotifier, LayerManager>(() {
  return LayerManagerNotifier();
});

class LayerManagerNotifier extends Notifier<LayerManager> {
  @override
  LayerManager build() {
    return const LayerManager(
      layers: [],
      objectLayers: [],
    );
  }

  void loadLayers(List<LayerItem> tempSavedLayers) {
    for (var layer in tempSavedLayers) {
      addLayer(layer);
    }
  }

  void setLayer() {
    List<LayerItem> layers = [];
    if (state.backgroundLayer != null) {
      layers.add(state.backgroundLayer!);
    }
    if (state.frameLayer != null) {
      layers.add(state.frameLayer!);
    }
    layers.addAll(state.objectLayers);
    if (state.drawingLayer != null) {
      layers.add(state.drawingLayer!);
    }
    setSelectedLayerItem(layers.last);
    setLayers(layers);
  }

  void addLayer(LayerItem item) {
    switch (item.type) {
      case BackgroundType():
        setBackgroundLayer(item);
        break;
      case FrameType():
        setFrameLayer(item);
        break;
      case DrawingType():
        setDrawingLayer(item);
        break;
      case TextType():
      case StickerType():
        addObjectLayer(item);
        break;
    }
    setSelectedLayerItem(item);
    setLayer();
  }

  void swap(LayerItem layer) {
    int index = state.objectLayers.indexWhere((item) => item.key == layer.key);
    if (index != -1) {
      removeObjectLayer(index);
      addObjectLayer(layer);
    }
    setSelectedLayerItem(layer);
    setLayer();
  }

  void setSelectedLayerItem(LayerItem? layer) {
    state = state.copyWith(selectedLayerItem: layer);
  }

  void initSelectedLayerItem() {
    state = state.copyWith(
        selectedLayerItem: LayerItem(
      key: UniqueKey(),
      type: const BackgroundType(),
      rect: Rect.zero,
      angle: 0,
      object: null,
    ));
  }

  void updateLayer(LayerItem layer) {
    int index = state.objectLayers.indexWhere((item) => item.key == layer.key);
    if (index != -1) {
      state = state.copyWith(objectLayers: [...state.objectLayers]..[index] = layer);
    }
  }

  void clearLayers() {
    setBackgroundLayer(null);
    setFrameLayer(null);
    setDrawingLayer(null);

    setObjectLayers([]);
  }

  void removeLayer(LayerItem layer) {
    if (state.layers == null) return;
    int index = state.layers!.indexWhere((item) => item.key == layer.key);
    if (index != -1) {
      state = state.copyWith(layers: [...state.layers!]..removeAt(index));
    }
  }

  setBackgroundLayer(LayerItem? layer) {
    state = state.copyWith(backgroundLayer: layer);
  }

  setDrawingLayer(LayerItem? layer) {
    state = state.copyWith(drawingLayer: layer);
  }

  setFrameLayer(LayerItem? layer) {
    state = state.copyWith(frameLayer: layer);
  }

  removeObjectLayer(int index) {
    state = state.copyWith(objectLayers: [...state.objectLayers]..removeAt(index));
  }

  addObjectLayer(LayerItem layer) {
    state = state.copyWith(objectLayers: [...state.objectLayers, layer]);
  }

  setObjectLayers(List<LayerItem> layers) {
    state = state.copyWith(objectLayers: layers);
  }

  setLayers(List<LayerItem> layers) {
    state = state.copyWith(layers: layers);
  }

  setSelectedLayerType(LayerType? type) {
    state = state.copyWith(selectedLayerType: type);
  }

  void removeLayerByType(LayerType type) {
    LayerItem? layer;
    switch (type) {
      case BackgroundType():
        layer = state.backgroundLayer;
        setBackgroundLayer(null);
        break;
      case FrameType():
        layer = state.frameLayer;
        setFrameLayer(null);
        break;
      case DrawingType():
        layer = state.drawingLayer;
        setDrawingLayer(null);
        break;
      default:
        break;
    }
    if (layer != null) {
      removeLayer(layer);
    }
  }

  void removeLayerByKey(Key key) {
    LayerItem? layer;
    if (state.backgroundLayer?.key == key) {
      layer = state.backgroundLayer;
      setBackgroundLayer(null);
    } else if (state.frameLayer?.key == key) {
      layer = state.frameLayer;
      setFrameLayer(null);
    } else if (state.drawingLayer?.key == key) {
      layer = state.drawingLayer;
      setDrawingLayer(null);
    } else {
      layer = state.objectLayers.where((item) => item.key == key).firstOrNull;
      state.objectLayers.remove(layer);
    }
    if (layer != null) {
      removeLayer(layer);
    }
  }

  void newKeyLayers() {
    if (state.backgroundLayer != null) {
      setBackgroundLayer(state.backgroundLayer!.newKey());
    }
    if (state.frameLayer != null) {
      setFrameLayer(state.frameLayer!.newKey());
    }
    if (state.drawingLayer != null) {
      setDrawingLayer(state.drawingLayer!.newKey());
    }

    for (int i = 0; i < state.objectLayers.length; i++) {
      state = state.copyWith(objectLayers: [...state.objectLayers]..[i] = state.objectLayers[i].newKey());
    }
  }
}

class LayerManager {
  final LayerItem? backgroundLayer;
  final LayerItem? frameLayer;
  final LayerItem? drawingLayer;
  final List<LayerItem> objectLayers;
  final List<LayerItem>? layers;
  final LayerType? selectedLayerType;
  final LayerItem? selectedLayerItem;
  const LayerManager({
    this.backgroundLayer,
    this.frameLayer,
    this.drawingLayer,
    this.objectLayers = const [],
    this.layers,
    this.selectedLayerType,
    this.selectedLayerItem,
  });
  LayerManager copyWith({
    LayerItem? backgroundLayer,
    LayerItem? frameLayer,
    LayerItem? drawingLayer,
    List<LayerItem>? objectLayers,
    List<LayerItem>? layers,
    LayerType? selectedLayerType,
    LayerItem? selectedLayerItem,
  }) {
    return LayerManager(
      backgroundLayer: backgroundLayer ?? this.backgroundLayer,
      frameLayer: frameLayer ?? this.frameLayer,
      drawingLayer: drawingLayer ?? this.drawingLayer,
      objectLayers: objectLayers ?? this.objectLayers,
      layers: layers ?? this.layers,
      selectedLayerType: selectedLayerType ?? selectedLayerType,
      selectedLayerItem: selectedLayerItem ?? selectedLayerItem,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LayerManager &&
        other.backgroundLayer == backgroundLayer &&
        other.frameLayer == frameLayer &&
        other.drawingLayer == drawingLayer &&
        listEquals(other.objectLayers, objectLayers) &&
        listEquals(other.layers, layers) &&
        other.selectedLayerType == selectedLayerType &&
        other.selectedLayerItem == selectedLayerItem;
  }

  @override
  int get hashCode {
    return backgroundLayer.hashCode ^
        frameLayer.hashCode ^
        drawingLayer.hashCode ^
        objectLayers.hashCode ^
        layers.hashCode ^
        selectedLayerType.hashCode ^
        selectedLayerItem.hashCode;
  }
}
