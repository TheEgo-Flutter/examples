import 'package:flutter/material.dart';
import 'package:image_editor/data/layer.dart';

/// Image layer that can be used to add overlay images and drawings
class ImageLayer extends StatefulWidget {
  final ImageLayerData layerData;
  final VoidCallback? onUpdate;

  const ImageLayer({
    super.key,
    required this.layerData,
    this.onUpdate,
  });

  @override
  createState() => _ImageLayerState();
}

class _ImageLayerState extends State<ImageLayer> {
  double initialSize = 0;
  double initialRotation = 0;

  @override
  Widget build(BuildContext context) {
    initialSize = widget.layerData.size;
    initialRotation = widget.layerData.rotation;

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
            widget.layerData.scale = detail.scale;
          }

          setState(() {});
        },
        child: Transform.rotate(
          angle: widget.layerData.rotation,
          child: Image.memory(
            widget.layerData.image.image,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
