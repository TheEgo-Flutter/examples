import 'package:flutter/rendering.dart';
import 'package:image_editor/utils/utils.dart';

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

class CenterWidthClip extends CustomClipper<Path> {
  final double width;

  CenterWidthClip({
    this.width = double.infinity,
  });

  @override
  Path getClip(Size size) {
    Rect rect = Rect.fromLTWH((size.width - width) / 2, 0, width, size.height);

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)))
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
