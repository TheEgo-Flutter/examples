import 'package:flutter/material.dart';

import 'colors_picker.dart';

class BlurData {
  Color color;
  double radius;
  Offset offset;
  double opacity;

  BlurData(this.color, this.radius, this.offset, this.opacity);
  BlurData.zero({
    this.color = Colors.transparent,
    this.radius = 0.0,
    this.offset = Offset.zero,
    this.opacity = 0.0,
  });
}

// ignore: must_be_immutable
class BlurLayer extends StatefulWidget {
  BlurLayer({Key? key, required this.onSelected, BlurData? blur})
      : blur = blur ?? BlurData.zero(),
        super(key: key);

  BlurData blur;
  final ValueChanged<Color> onSelected;

  @override
  State<BlurLayer> createState() => _BlurLayerState();
}

class _BlurLayerState extends State<BlurLayer> {
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
                      widget.blur.color = Color(value);
                    });
                    widget.onSelected(widget.blur.color);
                  },
                ),
              ),
              TextButton(
                child: const Text(
                  'Reset',
                ),
                onPressed: () {
                  setState(() {
                    widget.blur.color = Colors.transparent;
                  });
                  widget.onSelected(widget.blur.color);
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
                  value: widget.blur.radius,
                  min: 0.0,
                  max: 10.0,
                  onChanged: (v) {
                    setState(() {
                      widget.blur.radius = v;
                    });
                    widget.onSelected(widget.blur.color);
                  },
                ),
              ),
              TextButton(
                child: const Text(
                  'Reset',
                ),
                onPressed: () {
                  setState(() {
                    widget.blur.color = Colors.white;
                  });
                  widget.onSelected(widget.blur.color);
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
                  value: widget.blur.opacity,
                  min: 0.00,
                  max: 1.0,
                  onChanged: (v) {
                    setState(() {
                      widget.blur.opacity = v;
                    });
                    widget.onSelected(widget.blur.color);
                  },
                ),
              ),
              TextButton(
                child: const Text(
                  'Reset',
                ),
                onPressed: () {
                  setState(() {
                    widget.blur.opacity = 0.0;
                  });
                  widget.onSelected(widget.blur.color);
                },
              )
            ]),
          ],
        ),
      ),
    );
  }
}
