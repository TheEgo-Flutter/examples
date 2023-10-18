import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_card/utils/utils.dart';

class VerticalSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final Color thumbColor;
  final Color trackColor;

  const VerticalSlider({
    Key? key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
    this.thumbColor = Colors.blue,
    this.trackColor = Colors.white,
  }) : super(key: key);

  static double get width => GlobalRect().cardRect.width * 0.08;
  static double get height => GlobalRect().cardRect.height * 0.5;
  @override
  State<VerticalSlider> createState() => _VerticalSliderState();
}

class _VerticalSliderState extends State<VerticalSlider> {
  double _currentValue = 0;
  late double leftPosition;
  bool _maxVibrationTriggered = false;
  bool _minVibrationTriggered = false;

  double get defaultTop {
    double bottomInset = 0.0;
    double bottomLine = MediaQuery.of(context).size.height - GlobalRect().cardRect.bottom;

    if (bottomInsetNotifier.value > bottomLine) {
      bottomInset = bottomInsetNotifier.value - bottomLine;
    }
    return GlobalRect().cardRect.top + ((GlobalRect().cardRect.height * 0.25) - (bottomInset * 0.5));
  }

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    leftPosition = GlobalRect().objectRect.left - (VerticalSlider.width / 2);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      left: leftPosition,
      top: defaultTop,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onScaleStart: (details) {
          setState(() {
            leftPosition = GlobalRect().cardRect.left + (VerticalSlider.width / 2);
          });
        },
        onScaleEnd: (details) {
          setState(() {
            leftPosition = GlobalRect().objectRect.left - (VerticalSlider.width / 2);
          });
        },
        onScaleUpdate: (details) {
          final dy = details.localFocalPoint.dy.clamp(0, VerticalSlider.height);
          setState(() {
            _currentValue = widget.min + (widget.max - widget.min) * (1 - (dy / VerticalSlider.height));

            // max 값에 도달했을 때의 진동 조건
            if (_currentValue == widget.max && !_maxVibrationTriggered) {
              HapticFeedback.lightImpact();
              _maxVibrationTriggered = true;
            } else if (_currentValue < widget.max) {
              _maxVibrationTriggered = false;
            }

            // min 값에 도달했을 때의 진동 조건
            if (_currentValue == widget.min && !_minVibrationTriggered) {
              HapticFeedback.lightImpact();
              _minVibrationTriggered = true;
            } else if (_currentValue > widget.min) {
              _minVibrationTriggered = false;
            }

            widget.onChanged(_currentValue);
          });
        },
        child: SizedBox(
          width: VerticalSlider.width,
          height: VerticalSlider.height,
          child: CustomPaint(
            painter: _SliderPainter(
                _currentValue, widget.min, widget.max, widget.thumbColor, widget.trackColor.withOpacity(0.5)),
          ),
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
    final shadowPaint = Paint()
      ..strokeWidth = 1
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(trackPath, shadowPaint);
    canvas.drawPath(trackPath, trackPaint);
    double thumbY = trackBottom - (trackHeight) * ((value - min) / (max - min));
    canvas.drawShadow(Path()..addOval(Rect.fromCircle(center: Offset(size.width / 2, thumbY), radius: wideWidth)),
        Colors.black, 3.0, false);
    canvas.drawCircle(Offset(size.width / 2, thumbY), wideWidth, thumbPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
