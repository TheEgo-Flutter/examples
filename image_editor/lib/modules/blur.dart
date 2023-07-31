import 'package:flutter/material.dart';
import 'package:image_editor/layers/layer.dart';

import 'colors_picker.dart';

class Blur extends StatefulWidget {
  const Blur({
    Key? key,
    required this.blurLayer,
    required this.onSelected, // Add the onSelected callback
  }) : super(key: key);

  final BlurLayerData blurLayer;
  final ValueChanged<BlurLayerData> onSelected; // Updated this line

  @override
  State<Blur> createState() => _BlurState();
}

class _BlurState extends State<Blur> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.only(topRight: Radius.circular(10), topLeft: Radius.circular(10)),
        ),
        padding: const EdgeInsets.all(20),
        height: 400,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: BarColorPicker(
                  width: 300,
                  thumbColor: Colors.white,
                  cornerRadius: 10,
                  pickMode: PickMode.color,
                  colorListener: (int value) {
                    setState(() {
                      widget.blurLayer.color = Color(value);
                    });
                    widget.onSelected(widget.blurLayer);
                  },
                ),
              ),
              TextButton(
                child: const Text(
                  'Reset',
                ),
                onPressed: () {
                  setState(() {
                    widget.blurLayer.color = Colors.transparent;
                  });
                  widget.onSelected(widget.blurLayer);
                },
              )
            ]),
            const SizedBox(height: 5.0),
            const Text(
              'Blur Radius',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10.0),
            Row(children: [
              Expanded(
                child: Slider(
                  activeColor: Colors.white,
                  inactiveColor: Colors.grey,
                  value: widget.blurLayer.radius,
                  min: 0.0,
                  max: 10.0,
                  onChanged: (v) {
                    setState(() {
                      widget.blurLayer.radius = v;
                    });
                    widget.onSelected(widget.blurLayer);
                  },
                ),
              ),
              TextButton(
                child: const Text(
                  'Reset',
                ),
                onPressed: () {
                  setState(() {
                    widget.blurLayer.color = Colors.white;
                  });
                  widget.onSelected(widget.blurLayer);
                },
              )
            ]),
            const SizedBox(height: 5.0),
            const Text(
              'Color Opacity',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10.0),
            Row(children: [
              Expanded(
                child: Slider(
                  activeColor: Colors.white,
                  inactiveColor: Colors.grey,
                  value: widget.blurLayer.opacity,
                  min: 0.00,
                  max: 1.0,
                  onChanged: (v) {
                    setState(() {
                      widget.blurLayer.opacity = v;
                    });
                    widget.onSelected(widget.blurLayer);
                  },
                ),
              ),
              TextButton(
                child: const Text(
                  'Reset',
                ),
                onPressed: () {
                  setState(() {
                    widget.blurLayer.opacity = 0.0;
                  });
                  widget.onSelected(widget.blurLayer);
                },
              )
            ]),
          ],
        ),
      ),
    );
  }
}
