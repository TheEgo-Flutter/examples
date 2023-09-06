import 'package:flutter/rendering.dart';

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
