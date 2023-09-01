import 'package:flutter/material.dart';
import 'package:image_editor/utils/utils.dart';

Future<T?> customObjectBoxSizeDialog<T>({required BuildContext context, required Widget child}) {
  return showModalBottomSheet(
    context: context,
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
