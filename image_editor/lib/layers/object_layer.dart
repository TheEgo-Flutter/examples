import 'package:flutter/material.dart';
import 'package:image_editor/data/layer.dart';

class ObjectLayer extends StatefulWidget {
  final LayerData layerData;

  const ObjectLayer({
    super.key,
    required this.layerData,
  });
  @override
  createState() => _BaseLayerState();
}

class _BaseLayerState extends State<ObjectLayer> {
  double size = 0;
  double rotation = 0;
  @override
  void initState() {
    super.initState();
    size = widget.layerData.size;
    rotation = widget.layerData.rotation;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.layerData.offset.dx,
      top: widget.layerData.offset.dy,
      child: GestureDetector(
        onTap: () {},
        onScaleUpdate: (detail) {
          if (detail.pointerCount == 1) {
            widget.layerData.offset = Offset(
              widget.layerData.offset.dx + detail.focalPointDelta.dx,
              widget.layerData.offset.dy + detail.focalPointDelta.dy,
            );
          } else if (detail.pointerCount == 2) {
            widget.layerData.size = size + detail.scale * (detail.scale > 1 ? 1 : -1);
            size = widget.layerData.size;

            widget.layerData.rotation = detail.rotation;
            rotation = detail.rotation;
          }
          setState(() {});
        },
        child: Transform.rotate(
          angle: rotation,
          child: Container(
            padding: const EdgeInsets.all(64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: widget.layerData.object,
            ),
          ),
        ),
      ),
    );
  }
}
