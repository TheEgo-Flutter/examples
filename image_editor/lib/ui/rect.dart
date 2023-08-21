import 'dart:developer';

import 'package:flutter/rendering.dart';
import 'package:image_editor/utils/utils.dart';

Future<void> getRect() async {
  //* get card box rect
  final RenderBox? cardRenderBox = cardAreaKey.currentContext?.findRenderObject() as RenderBox?;
  if (cardRenderBox != null) {
    Offset offset = cardRenderBox.localToGlobal(Offset.zero);
    cardBoxRect = Rect.fromLTWH(offset.dx, offset.dy, cardRenderBox.size.width, cardRenderBox.size.height);
  }
  //* get object box rect
  final RenderBox? objectRenderBox = objectAreaKey.currentContext?.findRenderObject() as RenderBox?;
  if (objectRenderBox != null) {
    Offset offset = objectRenderBox.localToGlobal(Offset.zero);
    objectBoxRect = Rect.fromLTWH(offset.dx, offset.dy, objectRenderBox.size.width, objectRenderBox.size.height);
  }
  //* get delete area rect
  final RenderBox? deleteAreaRenderBox = deleteAreaKey.currentContext?.findRenderObject() as RenderBox?;
  if (cardRenderBox != null) {
    final Offset offset = deleteAreaRenderBox!.localToGlobal(Offset.zero) - cardBoxRect.topLeft;
    deleteAreaRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      deleteAreaRenderBox.size.width,
      deleteAreaRenderBox.size.height,
    );
  }

  log('_getRect card Box Rect : $cardBoxRect\nobject Box Rect : $objectBoxRect');
}

class CardBoxClip extends CustomClipper<Path> {
  final AspectRatioOption aspectRatio;

  CardBoxClip({
    this.aspectRatio = AspectRatioOption.rFree,
  });

  @override
  Path getClip(Size size) {
    double? ratio = aspectRatio.ratio;
    double w = 0.0;
    double h = size.height;
    if (ratio == null) {
      w = size.width;
    } else {
      w = h * ratio;
    }

    if (w > size.width) {
      w = size.width;
      h = w / (ratio ?? 1);
    }

    Rect rect = Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)))
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
