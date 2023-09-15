import 'package:flutter/material.dart';

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.iconData, required this.onPressed});
  final IconData iconData;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.grey[850],
      foregroundColor: Colors.white,
      child: IconButton(
        padding: const EdgeInsets.all(4.0),
        constraints: const BoxConstraints(),
        icon: Icon(iconData),
        onPressed: onPressed,
      ),
    );
  }
}
