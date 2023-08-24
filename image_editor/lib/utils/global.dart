import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Size device = Size(360.0, 800.0);
final GlobalKey cardAreaKey = GlobalKey();
Rect get cardBoxRect {
  final RenderBox? cardRenderBox = cardAreaKey.currentContext?.findRenderObject() as RenderBox?;
  if (cardRenderBox != null) {
    Offset offset = cardRenderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, cardRenderBox.size.width, cardRenderBox.size.height);
  }
  return Rect.zero;
}

final GlobalKey objectAreaKey = GlobalKey();
Rect get objectBoxRect {
  final RenderBox? objectRenderBox = objectAreaKey.currentContext?.findRenderObject() as RenderBox?;
  if (objectRenderBox != null) {
    Offset offset = objectRenderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, objectRenderBox.size.width, objectRenderBox.size.height);
  }
  return Rect.zero;
}

final GlobalKey deleteAreaKey = GlobalKey();
Rect get deleteAreaRect {
  final RenderBox? deleteAreaRenderBox = deleteAreaKey.currentContext?.findRenderObject() as RenderBox?;
  if (deleteAreaRenderBox != null) {
    final Offset offset = deleteAreaRenderBox.localToGlobal(Offset.zero) - cardBoxRect.topLeft;
    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      deleteAreaRenderBox.size.width,
      deleteAreaRenderBox.size.height,
    );
  }
  return Rect.zero;
}

ValueNotifier<double> bottomInsetNotifier = ValueNotifier<double>(0.0);

ThemeData theme = ThemeData().copyWith(
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    iconTheme: IconThemeData(color: Colors.white),
    systemOverlayStyle: SystemUiOverlayStyle.light,
    toolbarTextStyle: TextStyle(color: Colors.white),
    titleTextStyle: TextStyle(color: Colors.white),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.transparent,
  ),
  iconTheme: const IconThemeData(
    color: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white),
  ),
  inputDecorationTheme: const InputDecorationTheme().copyWith(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    border: InputBorder.none,
  ),
);
InputDecorationTheme get inputDecorationTheme => theme.inputDecorationTheme;
