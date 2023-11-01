import 'package:du_icons/du_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/helpers.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:photo_card/photo_card.dart';

class DrawingDataNotifier with ChangeNotifier {
  List<PaintContent> _drawingData;
  late final DrawingController _drawingController;
  DrawingDataNotifier(this._drawingData) {
    _drawingController = DrawingController(
        config: DrawConfig(
      contentType: SmoothLine,
      color: colors[0],
      strokeWidth: 8,
    ))
      ..addContents(_drawingData);
  }

  List<PaintContent> get drawingData => _drawingData;

  set drawingData(List<PaintContent> value) {
    _drawingData = value;
    notifyListeners();
  }

  DrawingController get drawingController => _drawingController;

  set drawingController(DrawingController value) {
    _drawingController = value;
    notifyListeners();
  }

  Future<(Uint8List, Size)?> getImageData(BuildContext context) async {
    final Uint8List? data = (await drawingController.getImageData())?.buffer.asUint8List();
    Size? size = drawingController.drawConfig.value.size; // same as cardRect.size
    return data == null || size == null ? null : (data, size);
  }
}

class BrushPainter extends StatefulWidget {
  const BrushPainter({super.key, required this.cardRadius, required this.drawingDataNotifier});
  final Radius cardRadius;
  final DrawingDataNotifier drawingDataNotifier;
  @override
  State<BrushPainter> createState() => _BrushPainterState();
}

class _BrushPainterState extends State<BrushPainter> {
  double min = 2;
  double max = 28;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void changeColor(Color color) {
    widget.drawingDataNotifier.drawingController.setPaintContent(SimpleLine());
    setState(() {
      widget.drawingDataNotifier.drawingController.drawConfig.value =
          widget.drawingDataNotifier.drawingController.drawConfig.value.copyWith(color: color);
    });
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
          widget.drawingDataNotifier.drawingData = widget.drawingDataNotifier.drawingController.getHistory
              .sublist(0, widget.drawingDataNotifier.drawingController.currentIndex);

          Navigator.pop(context);
        },
      ),
      center: ClipRRect(
        borderRadius: BorderRadius.all(widget.cardRadius),
        child: SizedBox(
          width: GlobalRect().cardRect.width,
          height: GlobalRect().cardRect.height,
          child: DrawingBoard(
            controller: widget.drawingDataNotifier.drawingController,
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
                    onPressed: () => widget.drawingDataNotifier.drawingController.undo(),
                    icon: const Icon(DUIcons.undo),
                    color: Colors.white,
                  ),
                  IconButton(
                    onPressed: () =>
                        widget.drawingDataNotifier.drawingController.setPaintContent(Eraser(color: Colors.white)),
                    icon: const Icon(DUIcons.eraser),
                    color: Colors.white,
                  )
                ],
              ),
              ColorBar(
                onColorChanged: changeColor,
                value: widget.drawingDataNotifier.drawingController.getColor,
              ),
            ],
          ),
        ),
      ),
      left: ExValueBuilder<DrawConfig>(
        valueListenable: widget.drawingDataNotifier.drawingController.drawConfig,
        shouldRebuild: (DrawConfig p, DrawConfig n) => p.strokeWidth != n.strokeWidth,
        builder: (_, DrawConfig dc, ___) {
          return VerticalSlider(
            min: min,
            max: max,
            value: dc.strokeWidth,
            thumbColor: accent,
            onChanged: (double v) => widget.drawingDataNotifier.drawingController.setStyle(strokeWidth: v),
          );
        },
      ),
    );
  }
}
