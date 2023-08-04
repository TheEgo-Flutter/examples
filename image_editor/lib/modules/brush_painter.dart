import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/helpers.dart';
import 'package:flutter_drawing_board/paint_contents.dart';

class BrushPainter extends StatefulWidget {
  const BrushPainter({Key? key}) : super(key: key);

  @override
  State<BrushPainter> createState() => _BrushPainterState();
}

class _BrushPainterState extends State<BrushPainter> {
  /// 绘制控制器
  final DrawingController _drawingController = DrawingController(
      config: DrawConfig(
    contentType: SmoothLine,
    color: Colors.black,
    strokeWidth: 15,
  ));
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _drawingController.dispose();
    super.dispose();
  }

  void changeColor(Color color) {
    _drawingController.drawConfig.value = _drawingController.drawConfig.value.copyWith(color: color);

    setState(() {});
  }

  Future<void> _getImageData(BuildContext context) async {
    final Uint8List? data = (await _drawingController.getImageData())?.buffer.asUint8List();
    if (data != null) {
      Widget widget = Image.memory(data);
      Navigator.pop(context, widget);
    }
  }

  Future<void> _getJson() async {
    showDialog<void>(
      context: context,
      builder: (BuildContext c) {
        return Center(
          child: Material(
            color: Colors.white,
            child: InkWell(
              onTap: () => Navigator.pop(c),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
                padding: const EdgeInsets.all(20.0),
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(_drawingController.getJsonList()),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(children: [
        DrawingBoard(
          controller: _drawingController,
          background: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.transparent,
          ),
          boardPanEnabled: false,
          boardScaleEnabled: false,
          showDefaultActions: false,
          showDefaultTools: false,
        ),
        Transform.translate(
          offset: const Offset(0, 0),
          child: buildAppBar(context),
        ),
      ]),
    );
  }

  Widget buildAppBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.format_size),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Brush Size'),
                  content: SizedBox(
                    height: 24,
                    width: 160,
                    child: ExValueBuilder<DrawConfig>(
                      valueListenable: _drawingController.drawConfig,
                      shouldRebuild: (DrawConfig p, DrawConfig n) => p.strokeWidth != n.strokeWidth,
                      builder: (_, DrawConfig dc, ___) {
                        return Slider(
                          value: dc.strokeWidth,
                          max: 50,
                          min: 1,
                          onChanged: (double v) => _drawingController.setStyle(strokeWidth: v),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
        ColorButton(
          color: _drawingController.getColor,
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
                return Theme(
                  data: ThemeData.from(colorScheme: ColorScheme.fromSeed(seedColor: Colors.black87)),
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.only(top: 16),
                      child: HueRingPicker(
                        pickerColor: _drawingController.getColor,
                        onColorChanged: changeColor,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed: () => _drawingController.undo(),
        ),
        IconButton(
          icon: const Icon(Icons.cleaning_services_rounded),
          onPressed: () => _drawingController.clear(),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _drawingController.setPaintContent(SimpleLine()),
        ),
        IconButton(
          icon: const Icon(Icons.brush),
          onPressed: () => _drawingController.setPaintContent(SmoothLine()),
        ),
        IconButton(
          icon: const Icon(Icons.phonelink_erase_rounded),
          onPressed: () => _drawingController.setPaintContent(Eraser(color: Colors.transparent)),
        ),
        //add check Icon _getImageData
        IconButton(icon: const Icon(Icons.check), onPressed: () => _getImageData(context)),
      ]),
    );
  }
}

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
