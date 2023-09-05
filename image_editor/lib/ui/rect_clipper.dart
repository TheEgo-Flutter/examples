import 'package:flutter/material.dart';
import 'package:image_editor/utils/utils.dart';

import 'rect.dart';

class TransformedWidget extends StatelessWidget {
  final ThemeData? themeData;
  final Widget? top;
  final Widget main;
  final Widget bottom;
  final Widget? left;
  final bool useWillPopScope;

  const TransformedWidget({
    super.key,
    this.themeData,
    this.top,
    required this.main,
    required this.bottom,
    this.left,
    this.useWillPopScope = false,
  });

  @override
  Widget build(BuildContext context) {
    return themeData != null
        ? Theme(
            data: themeData!,
            child: buildBody(context),
          )
        : buildBody(context);
  }

  Widget buildBody(BuildContext context) {
    Widget body = ClipPath(
      clipper: CenterWidthClip(width: objectBoxRect.width),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(children: [
          Center(
            child: Column(
              children: [
                if (top != null) top!,
                main,
                bottom,
              ],
            ),
          ),
          if (left != null) left!,
          // Container(
          //   //Random colors
          //   color: colors[math.Random().nextInt(colors.length)],
          //   width: cardBoxRect.width,
          //   height: cardBoxRect.height,
          //   transform: Matrix4.translationValues(cardBoxRect.left, cardBoxRect.top, 0),
          // )
        ]),
      ),
    );

    if (useWillPopScope) {
      return WillPopScope(onWillPop: () async => false, child: body);
    }
    return body;
  }
}

Future<T?> customObjectBoxSizeDialog<T>({required BuildContext context, required Widget child}) {
  return showModalBottomSheet(
    context: context,
    isDismissible: true,
    constraints: BoxConstraints(
      maxWidth: objectBoxRect.width,
      maxHeight: objectBoxRect.height,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(10),
      ),
    ),
    barrierColor: Colors.transparent,
    backgroundColor: const Color(0xff1C1C17),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
        child: child,
      );
    },
  );
}

Future<T?> customFullSizeDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.2),
    pageBuilder: (context, animation, secondaryAnimation) {
      return RectClipper(
        rect: cardBoxRect.expandToInclude(objectBoxRect),
        child: child,
      );
    },
  );
}

class RectClipper extends StatelessWidget {
  final Widget child;
  final Rect rect;

  const RectClipper({super.key, required this.child, required this.rect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Transform.translate(
        offset: Offset(rect.left, rect.top),
        child: SizedBox(
          width: rect.width,
          height: rect.height,
          child: child,
        ),
      ),
    );
  }
}
