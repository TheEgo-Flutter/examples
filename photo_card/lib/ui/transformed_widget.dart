import 'package:flutter/material.dart';
import 'package:photo_card/lib.dart';

class TransformedWidget extends StatefulWidget {
  final ThemeData themeData;
  final Widget? top;
  final Widget center;
  final Widget bottom;
  final Widget? left;
  final bool resizeToAvoidBottomInset;
  const TransformedWidget({
    super.key,
    required this.themeData,
    this.top,
    required this.center,
    required this.bottom,
    required this.resizeToAvoidBottomInset,
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
    return Theme(
      data: widget.themeData,
      child: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    Widget body = CustomPaint(
      painter: RectBlurPainter(GlobalRect().cardRect, MediaQuery.sizeOf(context), background),
      child: Scaffold(
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
        body: ClipPath(
          clipper: CenterWidthClip(width: GlobalRect().objectRect.width),
          child: Stack(
            children: [
              Transform.translate(
                offset: Offset(0, GlobalRect().cardRect.top),
                child: Center(
                  child: Column(
                    children: [
                      widget.center,
                      SizedBox(
                        height: GlobalRect().objectRect.top - GlobalRect().cardRect.bottom,
                      ),
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
      ),
    );

    return body;
  }
}

class RectBlurPainter extends CustomPainter {
  Rect? rect;
  Size? viewSize;
  final Color color;
  Paint fillPaint = Paint();

  RectBlurPainter(this.rect, this.viewSize, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (rect == null || viewSize == null) return;

    fillPaint.color = color;

    // 전체 화면의 경로 생성
    Path screenPath = Path()..addRect(Offset.zero & viewSize!);
    // 주어진 rect의 경로 생성
    Path rectPath = Path()..addRect(rect!);
    // 화면 전체에서 rect 부분을 제외한 경로 생성
    Path differencePath = Path.combine(PathOperation.difference, screenPath, rectPath);

    // 여집합 부분에만 색상 칠하기
    canvas.drawPath(differencePath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // 여기서는 무조건 다시 그리도록 설정했습니다. 최적화가 필요한 경우 조건을 수정하세요.
  }
}
