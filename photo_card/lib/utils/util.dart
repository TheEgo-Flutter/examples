import 'package:flutter/material.dart';

import 'global.rect.dart';

Size textSize(InlineSpan text, BuildContext context, {double maxWidth = double.infinity}) =>
    (TextPainter(text: text, textDirection: TextDirection.rtl, textScaleFactor: MediaQuery.textScaleFactorOf(context))
          ..layout(maxWidth: maxWidth))
        .size;

Offset getCenterOffset(Rect standardRect, Size size) => Offset(
      standardRect.size.width / 2 - size.width / 2,
      standardRect.size.height / 2 - size.height / 2,
    );

Future<T?> customObjectBoxSizeDialog<T>({required BuildContext context, required Widget child}) {
  return showModalBottomSheet(
    context: context,
    isDismissible: true,
    constraints: BoxConstraints(
      maxWidth: GlobalRect().objectRect.width,
      maxHeight: MediaQuery.of(context).size.height - GlobalRect().cardRect.bottom,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(10),
      ),
    ),
    barrierColor: Colors.transparent,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
        child: child,
      );
    },
  );
}

extension RectExtension on Rect {
  Rect get zero {
    return Rect.fromLTWH(0, 0, this.width, this.height);
  }
}

enum AspectRatioEnum {
  rFree('Free', null),
  photoCard('photoCard', 300 / 464),
  r1x1('1:1', 1),
  r3x4('3:4', 3 / 4),
  r4x5('4:5', 4 / 5),
  r5x7('5:7', 5 / 7),
  r9x16('9:16', 9 / 16);

  const AspectRatioEnum(this.title, this.ratio);
  final String title;
  final double? ratio;
}
