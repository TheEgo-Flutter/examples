import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/helpers.dart';
import 'package:flutter_drawing_board/paint_contents.dart';

import '../image_editor.dart';

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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _buildIconButton(context, Icons.format_size, () => _showBrushSizeDialog(context), '브러시 크기'),
        ColorButton(
          color: _drawingController.getColor,
          onTap: (color) => _showColorPicker(context, color),
        ),
        _buildIconButton(context, Icons.undo, _drawingController.undo),
        _buildIconButton(context, Icons.cleaning_services_rounded, _drawingController.clear),
        _buildIconButton(context, Icons.edit, () => _drawingController.setPaintContent(SimpleLine())),
        _buildIconButton(context, Icons.brush, () => _drawingController.setPaintContent(SmoothLine())),
        _buildIconButton(context, Icons.phonelink_erase_rounded,
            () => _drawingController.setPaintContent(Eraser(color: Colors.white))),
        _buildIconButton(context, Icons.check, () {
          drawingData = _drawingController.getHistory.sublist(0, _drawingController.currentIndex);
          _getImageData(context);
        }),
      ]),
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon, VoidCallback onPressed, [String? tooltip]) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  void _showBrushSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('브러시 크기'),
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
        DrawingBoard(
          controller: _drawingController,
          background: Container(
            width: cardRect.size.width,
            height: cardRect.size.height,
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
    this.margin = const EdgeInsets.symmetric(vertical: 16),
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap(color == Colors.transparent ? Colors.black : color);
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
