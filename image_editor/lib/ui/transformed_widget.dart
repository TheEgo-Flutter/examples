import 'package:flutter/material.dart';

import '../utils/global.rect.dart';
import 'clipper/center_clipper.dart';

class TransformedWidget extends StatefulWidget {
  final ThemeData? themeData;
  final Widget? top;
  final Widget center;
  final Widget bottom;
  final Widget? left;

  const TransformedWidget({
    super.key,
    this.themeData,
    this.top,
    required this.center,
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
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Transform.translate(
              offset: Offset(0, GlobalRect().cardRect.top),
              child: Center(
                child: Column(
                  children: [
                    widget.center,
                    widget.bottom,
                  ],
                ),
              ),
            ),
            if (widget.top != null)
              Positioned(
                top: GlobalRect().toolBarRect.top,
                left: GlobalRect().toolBarRect.left,
                child: widget.top!,
              ),
            if (widget.left != null) widget.left!,
          ],
        ),
      ),
    );

    return body;
  }
}
