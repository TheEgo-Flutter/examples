import 'package:flutter/material.dart';
import 'package:image_editor/data/layer.dart';

class StickerLayer extends StatefulWidget {
  final StickerLayerData layerData;
  final VoidCallback? onUpdate;

  const StickerLayer({
    super.key,
    required this.layerData,
    this.onUpdate,
  });

  @override
  createState() => _StickerLayerState();
}

class _StickerLayerState extends State<StickerLayer> {
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
            widget.layerData.size = initialSize + detail.scale * (detail.scale > 1 ? 1 : -1);

            // print('angle');
            // print(detail.rotation);
            widget.layerData.rotation = detail.rotation;
          }
          setState(() {});
        },
        child: Transform.rotate(
          angle: widget.layerData.rotation,
          child: Container(
            padding: const EdgeInsets.all(8),
            height: widget.layerData.size,
            width: widget.layerData.size,
            child: Image.asset(
              'assets/${widget.layerData.sticker}',
            ),
          ),
        ),
      ),
    );
  }
}
