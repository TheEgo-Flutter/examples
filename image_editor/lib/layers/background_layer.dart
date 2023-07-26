import 'package:flutter/material.dart';
import 'package:image_editor/data/layer.dart';

/// Main layer
class BackgroundLayer extends StatefulWidget {
  final BackgroundLayerData layerData;
  final VoidCallback? onUpdate;

  const BackgroundLayer({
    super.key,
    required this.layerData,
    this.onUpdate,
  });

  @override
  State<BackgroundLayer> createState() => _BackgroundLayerState();
}

class _BackgroundLayerState extends State<BackgroundLayer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // color: black,
      padding: EdgeInsets.zero,
      child: Image.memory(widget.layerData.file.image, fit: BoxFit.contain),
    );
  }
}
