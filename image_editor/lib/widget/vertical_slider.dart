import 'package:flutter/material.dart';

class VerticalSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final Color thumbColor;
  final Color trackColor;
  final double width; // 추가
  final double height; // 추가

  const VerticalSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.width, // 추가
    required this.height, // 추가
    this.min = 0.0,
    this.max = 100.0,
    this.thumbColor = Colors.blue, // default value
    this.trackColor = Colors.grey, // default value
  });

  @override
  State<VerticalSlider> createState() => _VerticalSliderState();
}

class _VerticalSliderState extends State<VerticalSlider> {
  double _currentValue = 0;
  Offset initPoint = Offset.zero;
  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final dy = details.localPosition.dy.clamp(0, widget.height);

        setState(() {
          double ratio = 1 - (dy / widget.height); // 현재 위치의 반대 비율을 계산 (1에서 빼줌)
          _currentValue = widget.min + (widget.max - widget.min) * ratio; // 반대 비율에 따른 _currentValue를 계산
          widget.onChanged(_currentValue);
        });
      },
      child: SizedBox(
        width: widget.width, // 수정
        height: widget.height, // 수정
        child: CustomPaint(
          painter: _SliderPainter(_currentValue, widget.min, widget.max, widget.thumbColor, widget.trackColor),
        ),
      ),
    );
  }
}

class _SliderPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color thumbColor;
  final Color trackColor;

  _SliderPainter(this.value, this.min, this.max, this.thumbColor, this.trackColor);

  @override
  void paint(Canvas canvas, Size size) {
    Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;

    Paint thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;

    double trackHeight = size.height - 20;
    double trackTop = (size.height - trackHeight) / 2;
    double trackBottom = trackTop + trackHeight;
    double narrowWidth = 1;
    double wideWidth = size.width / 2;

    Path trackPath = Path();
    trackPath.moveTo(size.width / 2 - narrowWidth, trackBottom);
    trackPath.lineTo(size.width / 2 + narrowWidth, trackBottom);
    trackPath.lineTo(size.width / 2 + wideWidth, trackTop);
    trackPath.lineTo(size.width / 2 - wideWidth, trackTop);
    trackPath.close();

    canvas.drawPath(trackPath, trackPaint);

    double thumbY = trackBottom - (trackHeight) * ((value - min) / (max - min));
    canvas.drawCircle(Offset(size.width / 2, thumbY), wideWidth, thumbPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
