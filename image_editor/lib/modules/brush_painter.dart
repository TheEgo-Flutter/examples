import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/helpers.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:image_editor/ui/rect.dart';

import '../utils/global.dart';

List<PaintContent> drawingData = [];

class BrushPainter extends StatefulWidget {
  const BrushPainter({Key? key}) : super(key: key);

  @override
  State<BrushPainter> createState() => _BrushPainterState();
}

class _BrushPainterState extends State<BrushPainter> {
  final DrawingController _drawingController = DrawingController(
      config: DrawConfig(
    contentType: SmoothLine,
    color: Colors.black,
    strokeWidth: 15,
  ))
    ..addContents(drawingData);

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
    Size? size = _drawingController.drawConfig.value.size; // same as cardRect.size
    Navigator.pop(context, (data, size));
  }

  Widget buildAppBar(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ExValueBuilder<DrawConfig>(
              valueListenable: _drawingController.drawConfig,
              shouldRebuild: (DrawConfig p, DrawConfig n) => p.strokeWidth != n.strokeWidth,
              builder: (_, DrawConfig dc, ___) {
                return SizedBox(
                  width: objectBoxRect.width * 0.4,
                  child: Slider(
                    value: dc.strokeWidth,
                    max: 30,
                    min: 1,
                    onChanged: (double v) => _drawingController.setStyle(strokeWidth: v),
                  ),
                );
              },
            ),
            TextButton(onPressed: _drawingController.undo, child: const Text('undo')),
            TextButton(onPressed: _drawingController.clear, child: const Text('clear')),
          ],
        ),
        SizedBox(
          width: objectBoxRect.width,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ColorButton(
                  color: _drawingController.getColor,
                  onTap: (color) => _showColorPicker(context, color),
                ),
                //Random generate ColorButton 10
                ...List.generate(
                  3,
                  (index) => ColorButton(
                    color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
                    onTap: changeColor,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                _buildIconButton(context, Icons.edit, () => _drawingController.setPaintContent(SimpleLine())),
                _buildIconButton(context, Icons.brush, () => _drawingController.setPaintContent(SmoothLine())),
                _buildIconButton(context, Icons.phonelink_erase_rounded,
                    () => _drawingController.setPaintContent(Eraser(color: Colors.white))),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('취소')),
            ),
            Expanded(
              child: ElevatedButton(
                  onPressed: () {
                    drawingData = _drawingController.getHistory.sublist(0, _drawingController.currentIndex);
                    _getImageData(context);
                  },
                  child: Text('완료')),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon, VoidCallback onPressed) {
    return InkWell(onTap: onPressed, child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon)));
  }

  void _showColorPicker(BuildContext context, Color color) {
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
          //check
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
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(children: [
        buildTop(),
        buildBottom(context),
      ]),
    );
  }

  DrawingBoard buildTop() {
    return DrawingBoard(
      controller: _drawingController,
      background: Container(
        width: cardBoxRect.size.width,
        height: cardBoxRect.size.height,
        color: Colors.transparent,
      ),
      boardPanEnabled: false,
      boardScaleEnabled: false,
      showDefaultActions: false,
      showDefaultTools: false,
    );
  }

  Transform buildBottom(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, objectBoxRect.top - cardBoxRect.top),
      child: SizedBox(
        height: objectBoxRect.height,
        // width: objectBoxRect.width,
        child: ClipPath(
          clipper: CardBoxClip(),
          child: Container(
            color: Colors.white,
            child: buildAppBar(context),
          ),
        ),
      ),
    );
  }
}

class ColorButton extends StatelessWidget {
  final Color color;
  final Function onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? margin;
  const ColorButton({
    Key? key,
    required this.color,
    required this.onTap,
    this.margin = const EdgeInsets.symmetric(vertical: 0),
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap(color == Colors.transparent ? Colors.black : color);
      },
      child: Container(
        height: 20,
        width: 20,
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
