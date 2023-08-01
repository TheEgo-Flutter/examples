import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hand_signature/signature.dart';

import '../layers/layer.dart';

class BrushPainter extends StatefulWidget {
  const BrushPainter({
    Key? key,
  }) : super(key: key);

  @override
  State<BrushPainter> createState() => _BrushPainterState();
}

class _BrushPainterState extends State<BrushPainter> {
  final control = HandSignatureControl(
    threshold: 3.0,
    smoothRatio: 0.65,
    velocityRange: 2.0,
  );

  Color pickerColor = Colors.white;
  Color currentColor = Colors.white;

  List<CubicPath> undoList = [];
  bool skipNextEvent = false;

  List<Color> colorList = [
    Colors.black,
    Colors.white,
    Colors.blue,
    Colors.green,
    Colors.pink,
    Colors.purple,
    Colors.brown,
    Colors.indigo,
    Colors.indigo,
  ];

  ValueNotifier<String?> svg = ValueNotifier<String?>(null);
  void changeColor(Color color) {
    currentColor = color;
    setState(() {});
  }

  @override
  void initState() {
    control.addListener(() {
      if (control.hasActivePath) return;

      if (skipNextEvent) {
        skipNextEvent = false;
        return;
      }

      undoList = [];
      setState(() {});
    });

    super.initState();
  }

  Widget buildAppBar() {
    return Row(children: [
      IconButton(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        icon: const Icon(Icons.clear),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      const Spacer(),
      IconButton(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        icon: Icon(
          Icons.undo,
          color: control.paths.isNotEmpty ? Colors.white : Colors.white.withAlpha(80),
        ),
        onPressed: () {
          if (control.paths.isEmpty) return;
          skipNextEvent = true;
          undoList.add(control.paths.last);
          control.stepBack();
          setState(() {});
        },
      ),
      IconButton(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        icon: Icon(
          Icons.redo,
          color: undoList.isNotEmpty ? Colors.white : Colors.white.withAlpha(80),
        ),
        onPressed: () {
          if (undoList.isEmpty) return;

          control.paths.add(undoList.removeLast());
          setState(() {});
        },
      ),
      IconButton(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        icon: const Icon(Icons.check),
        onPressed: () async {
          if (control.paths.isEmpty) return Navigator.pop(context);
          double minX = double.infinity;
          double minY = double.infinity;
          double maxX = double.negativeInfinity;
          double maxY = double.negativeInfinity;

          for (var path in control.paths) {
            for (var point in path.points) {
              if (point.dx < minX) minX = point.dx;
              if (point.dy < minY) minY = point.dy;
              if (point.dx > maxX) maxX = point.dx;
              if (point.dy > maxY) maxY = point.dy;
            }
          }

          double width = maxX - minX;
          double height = maxY - minY;

          Offset offset = Offset(minX, minY);

          String viewBox = "relativeOffset: $offset\nSize($width, $height)";
          log(viewBox);
          svg.value = control.toSvg(
            color: currentColor,
            type: SignatureDrawType.shape,
            fit: true,
          );
          if (!mounted) return;
          var svgPic = SvgPicture.string(
            svg.value!,
            fit: BoxFit.contain,
            width: width,
            height: height,
          );
          LayerData data = LayerData(
            key: UniqueKey(),
            object: svgPic,
            size: Size(width, height),
            offset: offset, // Use relative offset
          );
          return Navigator.pop(context, data);
        },
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: <Widget>[
            Container(
              constraints: const BoxConstraints.expand(),
              child: HandSignature(
                control: control,
                type: SignatureDrawType.shape,
                color: currentColor,
              ),
            ),
            CustomPaint(
              painter: DebugSignaturePainterCP(
                control: control,
                cp: false,
                cpStart: false,
                cpEnd: false,
              ),
            ),
            Transform.translate(
              offset: Offset(0, 0),
              child: buildAppBar(),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Row(
                children: [
                  ColorButton(
                    color: Colors.yellow,
                    onTap: (color) {
                      showModalBottomSheet(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            topLeft: Radius.circular(10),
                          ),
                        ),
                        context: context,
                        builder: (context) {
                          return Container(
                            color: Colors.black87,
                            padding: const EdgeInsets.all(20),
                            child: SingleChildScrollView(
                              child: Container(
                                padding: const EdgeInsets.only(top: 16),
                                child: HueRingPicker(
                                  pickerColor: pickerColor,
                                  onColorChanged: changeColor,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  for (int i = 0; i < colorList.length; i++)
                    ColorButton(
                      color: colorList[i],
                      onTap: (color) => changeColor(color),
                      isSelected: colorList[i] == currentColor,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Button used in bottomNavigationBar in ImageEditorDrawing
class ColorButton extends StatelessWidget {
  final Color color;
  final Function onTap;
  final bool isSelected;

  const ColorButton({
    super.key,
    required this.color,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap(color);
      },
      child: Container(
        height: 28,
        width: 28,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 23),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white54,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
