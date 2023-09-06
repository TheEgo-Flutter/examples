import 'package:flutter/material.dart';

import '../lib.dart';

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
        backgroundColor: Colors.transparent,
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

// class TransformedWidget2 extends StatefulWidget {
//   final ThemeData? themeData;
//   final Widget? top;
//   final Widget center;
//   final Widget bottom;
//   final Widget? left;

//   TransformedWidget2({
//     Key? key,
//     this.themeData,
//     this.top,
//     required this.center,
//     required this.bottom,
//     this.left,
//   }) : super(key: key);

//   @override
//   _TransformedWidget2State createState() => _TransformedWidget2State();
// }

// class _TransformedWidget2State extends State<TransformedWidget2> {
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => Navigator.of(context).pop(),
//       child: Stack(
//         children: [
//           if (widget.top != null)
//             Positioned(
//               top: GlobalRect().cardRect.top - kToolbarHeight,
//               left: GlobalRect().objectRect.left,
//               child: widget.top!,
//             ),
//           Positioned(
//             top: GlobalRect().cardRect.top,
//             left: GlobalRect().cardRect.left,
//             child: widget.center,
//           ),
//           Positioned(
//             top: GlobalRect().objectRect.top,
//             left: GlobalRect().objectRect.left,
//             child: widget.bottom,
//           ),
//           if (widget.left != null)
//             Positioned(
//               top: GlobalRect().cardRect.top +
//                   ((GlobalRect().cardRect.height * 0.25) - (GlobalRect().objectRect.left * 0.25)),
//               left: GlobalRect().objectRect.left - (VerticalSlider.width / 2),
//               child: widget.left!,
//             ),
//           Positioned(
//             top: GlobalRect().deleteRect.top,
//             left: GlobalRect().deleteRect.left,
//             child: Container(
//               width: GlobalRect().deleteRect.width,
//               height: GlobalRect().deleteRect.height,
//               color: Colors.green.withOpacity(0.6),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

