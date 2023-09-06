import 'package:flutter/material.dart';

class GlobalRect {
  static final GlobalRect _instance = GlobalRect._internal();

  factory GlobalRect() {
    return _instance;
  }

  GlobalRect._internal();

  // final GlobalKey toolBarAreaKey = GlobalKey();
  // final GlobalKey deleteAreaKey = GlobalKey();
  final GlobalKey cardAreaKey = GlobalKey();
  final GlobalKey objectAreaKey = GlobalKey();

  Rect get toolBarRect => _toolBarRectDefault;
  Rect get deleteRect => _deleteRectDefault;

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

  Rect get _deleteRectDefault => Rect.fromLTWH(
      GlobalRect().cardRect.left + (GlobalRect().cardRect.width * 0.4),
      GlobalRect().cardRect.bottom - (GlobalRect().cardRect.width * 0.2),
      GlobalRect().cardRect.width * 0.2,
      GlobalRect().cardRect.width * 0.2);

  Rect getRect(GlobalKey key) {
    final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }
}
