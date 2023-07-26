import 'package:flutter/widgets.dart';

import 'src.dart';

class ImagePosition with JsonAble {
  final Offset offset;
  final Size size;

  ImagePosition(
    this.offset,
    this.size,
  );

  @override
  Map<String, Object> toJson() {
    return {
      'x': offset.dx.toInt(),
      'y': offset.dy.toInt(),
      'w': size.width.toInt(),
      'h': size.height.toInt(),
    };
  }
}
