import 'package:flutter/material.dart';

const List<Color> colors = [
  Colors.black,
  Colors.white,
  Colors.red,
  Colors.orange,
  Colors.yellow,
  Colors.cyan,
  Colors.green,
  Colors.blue,
  Colors.indigo,
  Colors.purple
];

class ColorBar extends StatefulWidget {
  final Color? initialColor;
  final List<Color> colorList;
  final ValueChanged<Color> onColorChanged;
  const ColorBar({
    Key? key,
    this.initialColor,
    required this.onColorChanged,
    this.colorList = colors,
  }) : super(key: key);

  @override
  State<ColorBar> createState() => _ColorBarState();
}

class _ColorBarState extends State<ColorBar> {
  Color? selectedColor;
  @override
  void initState() {
    super.initState();
    widget.initialColor != null ? selectedColor = widget.initialColor : selectedColor = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.colorList.length,
        itemBuilder: (context, index) {
          return ColorChip(
            color: widget.colorList[index],
            isSelected: selectedColor == widget.colorList[index],
            onSelected: (bool selected) {
              if (selected) {
                setState(() {
                  selectedColor = widget.colorList[index];
                });
                widget.onColorChanged(widget.colorList[index]);
              }
            },
          );
        },
      ),
    );
  }
}

class ColorChip extends StatelessWidget {
  final Color color;
  final ValueChanged<bool> onSelected;
  final bool isSelected;
  const ColorChip({
    super.key,
    required this.color,
    required this.onSelected,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      visualDensity: const VisualDensity(vertical: -4),
      shape: const CircleBorder(),
      label: const SizedBox.shrink(), // No label is needed here
      selected: isSelected,
      side: const BorderSide(color: Colors.white, width: 1),
      labelPadding: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      selectedColor: color,
      backgroundColor: color,
      avatar: Padding(
        padding: EdgeInsets.zero,
        child: isSelected
            ? Icon(Icons.check, size: 32 / 2, color: color.computeLuminance() > 0.9 ? Colors.black : Colors.white)
            : null,
      ),

      onSelected: onSelected,
    );
  }
}
