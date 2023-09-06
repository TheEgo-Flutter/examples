import 'package:flutter/material.dart';
import 'package:image_editor/utils/global.dart';

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
      maxHeight: GlobalRect().objectRect.height,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(10),
      ),
    ),
    barrierColor: Colors.transparent,
    backgroundColor: const Color(0xff1C1C17),
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

  double _getResponsiveDimension(double rectSize, double deviceSize, double viewSize) {
    return rectSize * viewSize / deviceSize;
  }

  Size _getResponsiveSize(Size rectSize, Size deviceSize, Size viewSize) {
    return Size(
      _getResponsiveDimension(rectSize.width, deviceSize.width, viewSize.width),
      _getResponsiveDimension(rectSize.height, deviceSize.height, viewSize.height),
    );
  }

  Rect ratio(Size view) {
    Offset topLeft = Offset(
      _getResponsiveDimension(left, device.width, view.width),
      _getResponsiveDimension(top, device.height, view.height),
    );

    Size rectSize = _getResponsiveSize(
      Size(width, height),
      device,
      view,
    );

    return topLeft & rectSize;
  }
}

enum AspectRatioOption {
  rFree('Free', null),
  photoCard('photoCard', 300 / 464),
  r1x1('1:1', 1),
  r3x4('3:4', 3 / 4),
  r4x5('4:5', 4 / 5),
  r5x7('5:7', 5 / 7),
  r9x16('9:16', 9 / 16);

  const AspectRatioOption(this.title, this.ratio);
  final String title;
  final double? ratio;
}
