import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Renderer {
  final GlobalKey containerKey;

  Renderer({
    required this.containerKey,
  });

  Future<Uint8List?> capture({double pixelRatio = 3, Duration delay = const Duration(milliseconds: 20)}) async {
    return Future.delayed(delay, () async {
      try {
        ui.Image? image = await _captureAsUiImage(pixelRatio, Duration.zero);
        ByteData? byteData = await image?.toByteData(format: ui.ImageByteFormat.png);
        image?.dispose();
        return byteData?.buffer.asUint8List();
      } on Exception {
        throw Exception;
      }
    });
  }

  Future<ui.Image?> _captureAsUiImage(double pixelRatio, Duration delay) async {
    return Future.delayed(delay, () async {
      var findRenderObject = containerKey.currentContext?.findRenderObject();
      if (findRenderObject == null) {
        return null;
      }
      RenderRepaintBoundary boundary = findRenderObject as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      return image;
    });
  }
}
