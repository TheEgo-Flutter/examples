import 'package:flutter/material.dart';

import '../utils/global.rect.dart';

class GlobalToolBar extends StatelessWidget {
  final VoidCallback onConfirmPressed;
  final String confirmButtonText;

  const GlobalToolBar({
    super.key,
    required this.onConfirmPressed,
    this.confirmButtonText = '완료',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: GlobalRect().toolBarRect.width,
      height: GlobalRect().toolBarRect.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                '취소',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            TextButton(
              onPressed: onConfirmPressed,
              child: Text(
                confirmButtonText,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
