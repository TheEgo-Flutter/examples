import 'package:flutter/rendering.dart';

class CardBoxClip extends CustomClipper<Path> {
  double? width;

  @override
  Path getClip(Size size) {
    double h = size.height;
    double w = h * 9 / 16;

    if (h > size.height) {
      h = size.height;
      w = h * 16 / 9;
    }
    width = w;

    Rect rect = Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)))
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ObjectBoxClip extends CustomClipper<Path> {
  double width;

  ObjectBoxClip({required this.width});

  @override
  Path getClip(Size size) {
    if (width == 0) {
      width = size.width * 0.8;
    }

    Rect rect = Rect.fromLTWH(
        // 여기서 Rect 값을 저장합니다.
        (size.width - width) / 2,
        (size.height - size.height) / 2,
        width,
        size.height);

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)))
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
