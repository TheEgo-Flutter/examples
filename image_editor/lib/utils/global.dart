import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Rect cardBoxRect = Rect.zero;
final GlobalKey cardKey = GlobalKey();
Rect objectBoxRect = Rect.zero;
final GlobalKey objectAreaKey = GlobalKey();
Rect deleteAreaRect = Rect.zero;
final GlobalKey deleteAreaKey = GlobalKey();

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
);
