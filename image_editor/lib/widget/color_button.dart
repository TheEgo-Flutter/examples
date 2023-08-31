import 'package:flutter/material.dart';

class ColorButton extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? margin;
  const ColorButton({
    super.key,
    required this.color,
    required this.onTap,
    this.margin = const EdgeInsets.symmetric(vertical: 0),
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap(color == Colors.transparent ? Colors.black : color);
      },
      child: Container(
        height: 26,
        width: 26,
        margin: margin,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white54,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
