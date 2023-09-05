import 'package:flutter/material.dart';

import '../lib.dart';

class TransformedWidget extends StatefulWidget {
  final ThemeData? themeData;
  final Widget? top;
  final Widget main;
  final Widget bottom;
  final Widget? left;

  const TransformedWidget({
    super.key,
    this.themeData,
    this.top,
    required this.main,
    required this.bottom,
    this.left,
  });

  @override
  State<TransformedWidget> createState() => _TransformedWidgetState();
}

class _TransformedWidgetState extends State<TransformedWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.themeData != null
        ? Theme(
            data: widget.themeData!,
            child: buildBody(context),
          )
        : buildBody(context);
  }

  Widget buildBody(BuildContext context) {
    Widget body = ClipPath(
      clipper: CenterWidthClip(width: GlobalRect().objectRect.width),
      child: Scaffold(
        backgroundColor: Colors.green.withOpacity(0.4),
        resizeToAvoidBottomInset: true,
        body: Stack(children: [
          Center(
            child: Column(
              children: [
                if (widget.top != null) widget.top!,
                widget.main,
                widget.bottom,
              ],
            ),
          ),
          if (widget.left != null) widget.left!,
          Container(
            //Random colors
            color: Colors.pink.withOpacity(0.4),
            width: GlobalRect().cardRect.width,
            height: GlobalRect().cardRect.height,
            //status bar height
            transform: Matrix4.translationValues(GlobalRect().cardRect.left, GlobalRect().cardRect.top, 0),
          )
        ]),
      ),
    );

    return body;
  }
}

Future<T?> customObjectBoxSizeDialog<T>({required BuildContext context, required Widget child}) {
  return showModalBottomSheet(
    context: context,
    isDismissible: true,
    constraints: BoxConstraints(
      maxWidth: GlobalRect().objectRect.width,
      maxHeight: GlobalRect().objectRect.height,
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
