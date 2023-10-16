part of 'layer_manager.dart';

class LayerItem {
  final Key key;
  final LayerType type;
  final dynamic object;
  final Rect rect;
  final double angle;

  const LayerItem({
    required this.key,
    required this.type,
    required this.object,
    required this.rect,
    this.angle = 0,
  });

  LayerItem copyWith({
    Key? key,
    Rect? rect,
    double? angle,
    dynamic object,
    LayerType? layerType,
  }) {
    return LayerItem(
      key: key ?? this.key,
      type: type,
      object: object ?? this.object,
      rect: rect ?? this.rect,
      angle: angle ?? this.angle,
    );
  }

  LayerItem newKey() {
    return LayerItem(
      key: UniqueKey(),
      type: type,
      object: object,
      rect: rect,
      angle: angle,
    );
  }

  @override
  String toString() {
    return "LayerItem(rect: $rect, angle: $angle, key: $key, type: $type, object: $object)";
  }
}
