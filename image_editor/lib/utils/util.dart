import 'package:flutter/material.dart';

Size textSize(InlineSpan text, BuildContext context, {double maxWidth = double.infinity}) =>
    (TextPainter(text: text, textDirection: TextDirection.rtl, textScaleFactor: MediaQuery.textScaleFactorOf(context))
          ..layout(maxWidth: maxWidth))
        .size;

Offset getCenterOffset(Rect standardRect, Size size) => Offset(
      standardRect.size.width / 2 - size.width / 2,
      standardRect.size.height / 2 - size.height / 2,
    );

enum AspectRatioOption {
  rFree('Free', null),
  r1x1('1:1', 1),
  r4x3('4:3', 4 / 3),
  r5x4('5:4', 5 / 4),
  r7x5('7:5', 7 / 5),
  r16x9('9:16', 9 / 16);

  const AspectRatioOption(this.title, this.ratio);
  final String title;
  final double? ratio;
}
