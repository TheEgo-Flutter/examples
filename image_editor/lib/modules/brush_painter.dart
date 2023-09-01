import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/helpers.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:image_editor/ui/rect.dart';
import 'package:image_editor/utils/custom_color.g.dart';
import 'package:image_editor/widget/color_button.dart';

import '../utils/global.dart';
import '../widget/vertical_slider.dart';

List<PaintContent> drawingData = [];

class BrushPainter extends StatefulWidget {
  const BrushPainter({super.key});

  @override
  State<BrushPainter> createState() => _BrushPainterState();
}

class _BrushPainterState extends State<BrushPainter> {
  late final DrawingController _drawingController;
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
    setState(() {
      _drawingController.drawConfig.value = _drawingController.drawConfig.value.copyWith(color: color);
    });
  }

  Future<void> _getImageData(BuildContext context) async {
    final Uint8List? data = (await _drawingController.getImageData())?.buffer.asUint8List();
    Size? size = _drawingController.drawConfig.value.size; // same as cardRect.size
    Navigator.pop(context, (data, size));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: objectBoxRect.width,
                      height: kToolbarHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const BackButton(
                            color: Colors.white,
                          ),
                          IconButton(
                            onPressed: () {
                              drawingData = _drawingController.getHistory.sublist(0, _drawingController.currentIndex);
                              _getImageData(context);
                            },
                            icon: const Icon(Icons.check),
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    ClipPath(
                      clipper: CardBoxClip(aspectRatio: ratio),
                      child: SizedBox(
                        width: cardBoxRect.width,
                        height: cardBoxRect.height,
                        child: DrawingBoard(
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
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipPath(
                        clipper: CardBoxClip(),
                        child: Container(
                          width: objectBoxRect.width,
                          color: Colors.black,
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
                                    icon: const Icon(Icons.undo),
                                    color: Colors.white,
                                  ),
                                  IconButton(
                                    onPressed: () => _drawingController.setPaintContent(Eraser(color: Colors.white)),
                                    icon: const Icon(Icons.remove),
                                    color: Colors.white,
                                  )
                                ],
                              ),
                              ColorBar(
                                onColorChanged: changeColor,
                                initialColor: _drawingController.getColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Builder(builder: (context) {
                  double sliderHeight = cardBoxRect.height * 0.5;
                  double sliderWidth = cardBoxRect.width * 0.075;
                  double min = 2;
                  double max = 28;
                  return Transform.translate(
                    offset: Offset(
                        0, (cardBoxRect.height + kToolbarHeight) - (cardBoxRect.height + cardBoxRect.height * 0.5) / 2),
                    child: ExValueBuilder<DrawConfig>(
                      valueListenable: _drawingController.drawConfig,
                      shouldRebuild: (DrawConfig p, DrawConfig n) => p.strokeWidth != n.strokeWidth,
                      builder: (_, DrawConfig dc, ___) {
                        return VerticalSlider(
                          min: min,
                          max: max,
                          height: sliderHeight,
                          width: sliderWidth,
                          value: dc.strokeWidth,
                          thumbColor: customColors.accent!,
                          onChanged: (double v) => _drawingController.setStyle(strokeWidth: v),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ));
  }
}
