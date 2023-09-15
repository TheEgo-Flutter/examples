import 'package:du_icons/du_icons.dart';
import 'package:flutter/material.dart';

import '../lib.dart';

class DeleteArea extends StatelessWidget {
  const DeleteArea({
    super.key,
    required this.visible,
  });
  final bool visible;
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: CardRect().deleteRect.top,
      left: CardRect().deleteRect.left,
      child: Opacity(
        opacity: visible ? 1.0 : 0.0,
        child: Container(
          width: CardRect().deleteRect.width,
          height: CardRect().deleteRect.height,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: label, width: 2),
            color: Colors.transparent,
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  offset: Offset(0, 1), // 그림자의 위치 조정
                  blurStyle: BlurStyle.outer),
            ],
          ),
          child: const Icon(
            DUIcons.trash_empty,
            color: label,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(0, 0), // 그림자의 위치 조정
              ),
            ],
          ),
        ),
      ),
    );
  }
}
