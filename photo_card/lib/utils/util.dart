import 'package:flutter/material.dart';

import 'global.rect.dart';

Size textSize(InlineSpan text, BuildContext context, {double maxWidth = double.infinity}) => (TextPainter(
      text: text,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      textScaleFactor: MediaQuery.textScaleFactorOf(context),
    )..layout(maxWidth: maxWidth))
        .size;

// Size getTextSize(String text, double fontSize, FontWeight fontWeight) {
//   final textStyle = TextStyle(
//     fontSize: fontSize,
//     fontWeight: fontWeight,
//   );

//   final textPainter = TextPainter(
//     text: TextSpan(text: text, style: textStyle),
//     textDirection: TextDirection.ltr,
//   );

//   textPainter.layout();

//   return textPainter.size;
// }

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
