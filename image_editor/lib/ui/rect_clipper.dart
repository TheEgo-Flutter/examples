import 'package:flutter/material.dart';
import 'package:image_editor/utils/utils.dart';

Future<T?> customObjectBoxSizeDialog<T>({required BuildContext context, required Widget child}) {
  return showModalBottomSheet(
    context: context,
    constraints: BoxConstraints(
      maxWidth: cardBoxRect.width,
      maxHeight: objectBoxRect.height,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    barrierColor: Colors.transparent,
    backgroundColor: Colors.black,
    builder: (BuildContext context) {
      return child;
    },
  );
}

Future<T?> customFullSizeDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showGeneralDialog(
    context: context,
    barrierColor: Colors.transparent,
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
