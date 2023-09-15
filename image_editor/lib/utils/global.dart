import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/utils/util.dart';

AspectRatioEnum ratio = AspectRatioEnum.photoCard;

const Size device = Size(360.0, 800.0);

const EdgeInsets cardPadding = EdgeInsets.symmetric(horizontal: 16.0);

ValueNotifier<double> bottomInsetNotifier = ValueNotifier<double>(0.0);
const background = Color(0xff1D1D1D);
const canvas = Color(0xFFFFFFFF);
const label = Color(0xFFFFFFFF);
const accent = Color(0xFFD2F002);
const bottomSheet = Color(0xff353535);
const bottomItem = Color(0xFF545454);

ThemeData theme = ThemeData().copyWith(
  cardColor: canvas,

  ///background color of the scaffold
  scaffoldBackgroundColor: background,
  canvasColor: background,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    iconTheme: IconThemeData(color: label),
    systemOverlayStyle: SystemUiOverlayStyle.light,
    toolbarTextStyle: TextStyle(color: label),
    titleTextStyle: TextStyle(color: label),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: bottomSheet,
  ),
  iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
    splashFactory: NoSplash.splashFactory,
  )),
  iconTheme: const IconThemeData(
    color: label,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: label),
  ),
  inputDecorationTheme: const InputDecorationTheme().copyWith(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    border: InputBorder.none,
  ),
);
InputDecorationTheme get inputDecorationTheme => theme.inputDecorationTheme;
