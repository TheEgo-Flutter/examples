import 'package:du_icons/du_icons.dart';
import 'package:flutter/material.dart';

class DeleteArea extends StatelessWidget {
  const DeleteArea({
    super.key,
    required this.visible,
  });
  final bool visible;
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: visible ? 1.0 : 0.0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green[900]!, width: 2),
            color: Colors.white,
          ),
          child: Icon(
            DUIcons.trash_empty,
            color: Colors.green[900],
          ),
        ),
      ),
    );
  }
}
