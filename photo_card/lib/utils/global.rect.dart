import 'package:flutter/material.dart';

class CardRect {
  static final CardRect _instance = CardRect._internal();

  factory CardRect() {
    return _instance;
  }

  CardRect._internal();
  Rect get deleteRect => _deleteRectDefault;
  double get width => GlobalRect().cardRect.width * 0.15;
  Rect get _deleteRectDefault => Rect.fromLTWH(
        GlobalRect().cardRect.bottomCenter.dx - (width / 2),
        GlobalRect().cardRect.bottomCenter.dy - (width * 1.2),
        width,
        width,
      ).shift(-GlobalRect().cardRect.topLeft);
}

class GlobalRect {
  static final GlobalRect _instance = GlobalRect._internal();

  factory GlobalRect() {
    return _instance;
  }

  GlobalRect._internal();

  final GlobalKey cardAreaKey = GlobalKey();
  final GlobalKey objectAreaKey = GlobalKey();

  Rect get toolBarRect => _toolBarRectDefault;

  Size get stickerSize => Size(cardRect.size.width / 3, cardRect.size.width / 3);

  double get statusBarSize => _statusBarSize ?? 0;
  double? _statusBarSize;
  set statusBarSize(double? value) {
    _statusBarSize = value;
  }

  Rect get cardRect => _cardRect ?? Rect.zero;
  Rect? _cardRect;
  set cardRect(Rect? value) {
    _cardRect = value;
  }

  Rect get objectRect => _objectRect ?? Rect.zero;
  Rect? _objectRect;
  set objectRect(Rect? value) {
    _objectRect = value;
  }

  Rect get _toolBarRectDefault => Rect.fromLTWH(objectRect.left, statusBarSize, objectRect.width, kToolbarHeight);

  Rect getRect(GlobalKey key) {
    final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }
}
