import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/utils/utils.dart';

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

  @override
  State<VerticalSlider> createState() => _VerticalSliderState();
}

class _VerticalSliderState extends State<VerticalSlider> {
  double _currentValue = 0;
  late double leftPosition;
  bool _maxVibrationTriggered = false;
  bool _minVibrationTriggered = false;

  double get width => cardBoxRect.width * 0.08;
  double get height => cardBoxRect.height * 0.5;
  double defaultTop(double inset) {
    inset > cardBoxRect.bottom ? inset = 0 : inset = inset;
    return cardBoxRect.top + ((cardBoxRect.height - inset) * 0.25);
  }

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    leftPosition = objectBoxRect.left - (width / 2);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ValueListenableBuilder(
            valueListenable: bottomInsetNotifier,
            builder: (context, bottomInset, child) {
              return AnimatedPositioned(
                left: leftPosition,
                top: defaultTop(bottomInset),
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onScaleStart: (details) {
                    setState(() {
                      leftPosition = cardBoxRect.left + (width / 2);
                    });
                  },
                  onScaleEnd: (details) {
                    setState(() {
                      leftPosition = objectBoxRect.left - (width / 2);
                    });
                  },
                  onScaleUpdate: (details) {
                    final dy = details.localFocalPoint.dy.clamp(0, height);
                    setState(() {
                      _currentValue = widget.min + (widget.max - widget.min) * (1 - (dy / height));

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
                    width: width,
                    height: height,
                    child: CustomPaint(
                      painter: _SliderPainter(
                          _currentValue, widget.min, widget.max, widget.thumbColor, widget.trackColor.withOpacity(0.5)),
                    ),
                  ),
                ),
              );
            }),
      ],
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
