import 'package:flutter/material.dart';

class AnimatedToggle extends StatefulWidget {
  final List<String> values;
  final ValueChanged onToggleCallback;
  final Color backgroundColor;
  final Color buttonColor;
  final Color textColor;

  AnimatedToggle({
    required this.values,
    required this.onToggleCallback,
    this.buttonColor = const Color(0xFFFFFFFF),
    this.backgroundColor = const Color(0xFF939393),
    this.textColor = const Color(0xFF000000),
  });
  @override
  _AnimatedToggleState createState() => _AnimatedToggleState();
}

class _AnimatedToggleState extends State<AnimatedToggle> {
  bool initialPosition = true;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final height = constraints.maxWidth * 0.4;
      final width = constraints.maxWidth * 0.6;
      final round = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(constraints.maxWidth * 0.1),
      );
      return Container(
        width: width,
        height: height,
        margin: EdgeInsets.all(height * 0.1),
        child: Stack(
          children: <Widget>[
            SizedBox(
              width: width,
              child: GestureDetector(
                onTap: () {
                  initialPosition = !initialPosition;
                  var index = 0;
                  if (!initialPosition) {
                    index = 1;
                  }
                  widget.onToggleCallback(index);
                  setState(() {});
                },
                child: Container(
                  width: width,
                  height: height,
                  decoration: ShapeDecoration(
                    color: widget.backgroundColor,
                    shape: round,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05),
                        child: Text(
                          widget.values[0],
                          style: TextStyle(
                            fontSize: constraints.maxWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: widget.buttonColor,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05),
                        child: Text(
                          widget.values[1],
                          style: TextStyle(
                            fontSize: constraints.maxWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: widget.buttonColor,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.decelerate,
              alignment: initialPosition ? Alignment.centerLeft : Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.all(constraints.maxWidth * 0.01),
                child: Container(
                  width: constraints.maxWidth * 0.3,
                  height: height,
                  decoration: ShapeDecoration(
                    color: widget.buttonColor,
                    shape: round,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initialPosition ? widget.values[0] : widget.values[1],
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: constraints.maxWidth * 0.045,
                      color: widget.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
