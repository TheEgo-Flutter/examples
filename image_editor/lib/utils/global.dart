import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/utils/custom_color.g.dart';
import 'package:image_editor/utils/util.dart';

AspectRatioOption ratio = AspectRatioOption.photoCard;

const Size device = Size(360.0, 800.0);

const EdgeInsets cardPadding = EdgeInsets.symmetric(horizontal: 16.0);

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
    backgroundColor: Color(0xff353535),
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
