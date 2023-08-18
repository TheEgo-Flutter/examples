import 'package:flutter/rendering.dart';

class CardBoxClip extends CustomClipper<Path> {
  double width = 0.0;
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
  ObjectBoxClip();

  @override
  Path getClip(Size size) {
    double h = size.height;
    double w = size.width; // CardBoxClip의 width와 동일하게 설정

    Rect rect = Rect.fromLTWH(0, 0, w, h);

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)))
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
