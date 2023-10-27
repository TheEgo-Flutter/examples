import 'package:du_icons/du_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/helpers.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:photo_card/ui/ui.dart';
import 'package:photo_card/utils/global.dart';

import '../utils/global.rect.dart';

class BrushPainter extends StatefulWidget {
  const BrushPainter({super.key, required this.cardRadius});
  final Radius cardRadius;
  @override
  State<BrushPainter> createState() => _BrushPainterState();
}

class _BrushPainterState extends State<BrushPainter> {
  late final DrawingController _drawingController;

  double min = 2;
  double max = 28;
  @override
  void initState() {
    super.initState();
    _drawingController = DrawingController(
        config: DrawConfig(
      contentType: SmoothLine,
      color: colors[0],
      strokeWidth: 8,
    ))
      ..addContents(drawingData);
  }

  @override
  void dispose() {
    _drawingController.dispose();
    super.dispose();
  }

  void changeColor(Color color) {
    _drawingController.setPaintContent(SimpleLine());
    setState(() {
      _drawingController.drawConfig.value = _drawingController.drawConfig.value.copyWith(color: color);
    });
  }

  Future<(Uint8List, Size)?> _getImageData(BuildContext context) async {
    final Uint8List? data = (await _drawingController.getImageData())?.buffer.asUint8List();
    Size? size = _drawingController.drawConfig.value.size; // same as cardRect.size
    return data == null || size == null ? null : (data, size);
  }

  @override
  Widget build(BuildContext context) {
    return TransformedWidget(
      resizeToAvoidBottomInset: false,
      themeData: ThemeData().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.black,
        ),
      ),
      top: GlobalToolBar(
        onConfirmPressed: () async {
          drawingData = _drawingController.getHistory.sublist(0, _drawingController.currentIndex);

          Navigator.pop(context, await _getImageData(context));
        },
      ),
      center: ClipRRect(
        borderRadius: BorderRadius.all(widget.cardRadius),
        child: SizedBox(
          width: GlobalRect().cardRect.width,
          height: GlobalRect().cardRect.height,
          child: DrawingBoard(
            controller: _drawingController,
            background: Container(
              width: GlobalRect().cardRect.width,
              height: GlobalRect().cardRect.height,
              color: Colors.transparent,
            ),
            boardPanEnabled: false,
            boardScaleEnabled: false,
            showDefaultActions: false,
            showDefaultTools: false,
          ),
        ),
      ),
      bottom: Expanded(
        child: SizedBox(
          width: GlobalRect().objectRect.width,
          height: GlobalRect().objectRect.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => _drawingController.undo(),
                    icon: const Icon(DUIcons.undo),
                    color: Colors.white,
                  ),
                  IconButton(
                    onPressed: () => _drawingController.setPaintContent(Eraser(color: Colors.white)),
                    icon: const Icon(DUIcons.eraser),
                    color: Colors.white,
                  )
                ],
              ),
              ColorBar(
                onColorChanged: changeColor,
                value: _drawingController.getColor,
              ),
            ],
          ),
        ),
      ),
      left: ExValueBuilder<DrawConfig>(
        valueListenable: _drawingController.drawConfig,
        shouldRebuild: (DrawConfig p, DrawConfig n) => p.strokeWidth != n.strokeWidth,
        builder: (_, DrawConfig dc, ___) {
          return VerticalSlider(
            min: min,
            max: max,
            value: dc.strokeWidth,
            thumbColor: accent,
            onChanged: (double v) => _drawingController.setStyle(strokeWidth: v),
          );
        },
      ),
    );
  }
}
