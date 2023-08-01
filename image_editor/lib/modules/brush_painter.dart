import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hand_signature/signature.dart';
import 'package:image_editor/image_editor.dart';

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
  ];

  ValueNotifier<List<String?>> svg = ValueNotifier<List<String?>>([]);
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
      if (control.paths.isEmpty) {
        svg.value.add(control.toSvg(
          color: currentColor,
          type: SignatureDrawType.shape,
          fit: true,
        ));
        log(svg.value.last ?? '');
        control.stepBack();
      }

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

          if (!mounted) return;
          // var svgPic = SvgPicture.string(
          //   svg.value!,
          //   fit: BoxFit.contain,
          //   width: width,
          //   height: height,
          // );
          // LayerData data = LayerData(
          //   key: UniqueKey(),
          //   object: svgPic,
          //   size: Size(width, height),
          //   offset: offset, // Use relative offset
          // );
          // return Navigator.pop(context, data);
        },
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        svg.value.isNotEmpty && svg.value.last != null
            ? SvgPicture.string(
                svg.value.last!,
                fit: BoxFit.contain,
                width: cardSize.width,
                height: cardSize.height,
              )
            : const SizedBox.shrink(),
        Container(
          constraints: const BoxConstraints.expand(),
          child: HandSignature(
            control: control,
            type: SignatureDrawType.shape,
            color: currentColor,
          ),
        ),
        // CustomPaint(
        //   painter: DebugSignaturePainterCP(
        //     control: control,
        //     cp: false,
        //     cpStart: false,
        //     cpEnd: false,
        //   ),
        // ),
        Transform.translate(
          offset: const Offset(0, 0),
          child: buildAppBar(),
        ),
        Transform.translate(
            offset: Offset(0, cardSize.height - 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        stops: [
                          0.1,
                          0.4,
                          0.6,
                          0.9,
                        ],
                        colors: [
                          Colors.yellow,
                          Colors.red,
                          Colors.indigo,
                          Colors.teal,
                        ],
                      )),
                  child: ColorButton(
                    color: Colors.transparent,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    onTap: (color) {
                      showModalBottomSheet(
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
                ),
                for (int i = 0; i < colorList.length; i++)
                  ColorButton(
                    color: colorList[i],
                    onTap: (color) => changeColor(color),
                    isSelected: colorList[i] == currentColor,
                  ),
              ],
            )),
      ],
    );
  }
}

/// Button used in bottomNavigationBar in ImageEditorDrawing
class ColorButton extends StatelessWidget {
  final Color color;
  final Function onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? margin;
  const ColorButton({
    super.key,
    required this.color,
    required this.onTap,
    this.margin = const EdgeInsets.symmetric(vertical: 16),
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap(color);
      },
      child: Container(
        height: 24,
        width: 24,
        margin: margin,
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
