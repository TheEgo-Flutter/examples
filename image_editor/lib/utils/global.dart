import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/utils/custom_color.g.dart';
import 'package:image_editor/utils/util.dart';

// const _iconButton = IconButton(
//   icon:  Icon(Icons.add),
//   onPressed: null,
// );
// final iconButtonSize = _iconButton.constraints?.minHeight ?? 32.0;
AspectRatioOption ratio = AspectRatioOption.r9x16;
const Size device = Size(360.0, 800.0);
// Expanded 내부의 Padding 값
const EdgeInsets cardPadding = EdgeInsets.symmetric(horizontal: 16.0);
final GlobalKey toolBarAreaKey = GlobalKey();
Rect get toolBarBoxRect {
  final RenderBox? cardRenderBox = toolBarAreaKey.currentContext?.findRenderObject() as RenderBox?;
  if (cardRenderBox != null) {
    Offset offset = cardRenderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, cardRenderBox.size.width, cardRenderBox.size.height);
  }
  return Rect.zero;
}

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
  extensions: [customColors],
  canvasColor: customColors.background,
  cardColor: customColors.canvas,
  scaffoldBackgroundColor: customColors.canvas,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    iconTheme: IconThemeData(color: customColors.label),
    systemOverlayStyle: SystemUiOverlayStyle.light,
    toolbarTextStyle: TextStyle(color: customColors.label),
    titleTextStyle: TextStyle(color: customColors.label),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.transparent,
  ),
  iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
    splashFactory: NoSplash.splashFactory,
  )),
  iconTheme: IconThemeData(
    color: customColors.label,
  ),
  textTheme: TextTheme(
    bodyMedium: TextStyle(color: customColors.label),
  ),
  inputDecorationTheme: const InputDecorationTheme().copyWith(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    border: InputBorder.none,
  ),
);
InputDecorationTheme get inputDecorationTheme => theme.inputDecorationTheme;
