import 'package:flutter/material.dart';
import 'package:image_editor/data/layer.dart';

class BackgroundLayer extends StatefulWidget {
  final BaseLayerData layerData;

  const BackgroundLayer({
    super.key,
    required this.layerData,
  });

  @override
  State<BackgroundLayer> createState() => _BackgroundLayerState();
}

class _BackgroundLayerState extends State<BackgroundLayer> {
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
    return Center(
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
          },
          child: Transform.rotate(
            angle: widget.layerData.rotation,
            child: Image.memory(widget.layerData.file.image, fit: BoxFit.contain),
          )),
    );
  }
}
