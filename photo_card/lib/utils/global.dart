import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:photo_card/lib.dart';

List<PaintContent> drawingData = [];
AspectRatioEnum ratio = AspectRatioEnum.photoCard;

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
);
