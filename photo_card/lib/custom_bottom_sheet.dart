import 'package:flutter/material.dart';
import 'package:photo_card/lib.dart';

Future<void> customBottomSheet({
  BuildContext? context,
  String? title,
  TextStyle? titleStyle,
  required Widget contents,
  double titleSpace = 40,
  bool dismissible = true,
  bool scrollable = true,
  EdgeInsets padding = const EdgeInsets.only(top: 20),
  double itemSpace = 20,
  double cancelBtnSpace = 40,
  final Function? bottomButton,
}) async {
  await showModalBottomSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context!).size.height * 0.7,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      backgroundColor: bottomSheet,
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: contents,
                ),
              ],
            ),
          ),
        );
      });
}
