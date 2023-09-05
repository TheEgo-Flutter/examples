import 'package:flutter/material.dart';

import '../lib.dart';

/// 사용 예:
/// CustomSizedBox(
///   width: GlobalRect().objectRect.width,
///   height: kToolbarHeight,
///   onConfirmPressed: () {
///     // 원하는 로직 입력
///   },
/// );
class GlobalToolBar extends StatelessWidget {
  final VoidCallback onConfirmPressed;
  final String confirmButtonText;

  const GlobalToolBar({
    super.key,
    required this.onConfirmPressed,
    this.confirmButtonText = '확인',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // transform: Matrix4.translationValues(
      //   GlobalRect().objectRect.left,
      //   GlobalRect().objectRect.top,
      //   0.0,
      // ),
      width: GlobalRect().toolBarRect.width,
      height: GlobalRect().toolBarRect.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: const SizedBox(
              height: kToolbarHeight,
              child: Center(
                child: Text(
                  '취소',
                  style: TextStyle(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0),
                        blurRadius: 3.0,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onConfirmPressed,
            child: SizedBox(
              height: kToolbarHeight,
              child: Center(
                child: Text(
                  confirmButtonText,
                  style: const TextStyle(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0),
                        blurRadius: 3.0,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
