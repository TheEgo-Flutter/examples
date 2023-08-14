import 'package:flutter/material.dart';

class PositionedWidget extends StatelessWidget {
  final Widget child;
  final Size size;
  final Offset offset;

  const PositionedWidget({super.key, required this.child, required this.size, required this.offset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Transform.translate(
        offset: Offset(offset.dx, offset.dy),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }
}
