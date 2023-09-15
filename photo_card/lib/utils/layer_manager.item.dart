part of 'layer_manager.dart';

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

  LayerItem newKey() {
    return LayerItem(
      UniqueKey(),
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
