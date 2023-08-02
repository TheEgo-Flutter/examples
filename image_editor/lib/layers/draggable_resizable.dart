import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_editor/image_editor.dart';

import 'matrix_gesture_detector.dart';

class DraggableResizable extends StatelessWidget {
  DraggableResizable.background({
    super.key = backgroundKey,
    required Uint8List? uint8List,
    required Size size,
    VoidCallback? onDragStart,
    VoidCallback? onDragEnd,
    VoidCallback? onDelete,
    bool canTransform = false,
  }) : _widget = uint8List != null
            ? DraggableBase(
                key: key,
                size: size,
                onDragStart: onDragStart,
                onDragEnd: onDragEnd,
                canTransform: canTransform,
                child: Image.memory(
                  uint8List,
                  fit: BoxFit.cover,
                ),
              )
            : const SizedBox.shrink();
  DraggableResizable.object({
    required Key key,
    required Widget child,
    required Size size,
    VoidCallback? onDragStart,
    VoidCallback? onDragEnd,
    VoidCallback? onDelete,
    bool canTransform = false,
  })  : _widget = DraggableBase(
          key: key,
          size: size,
          onDragStart: onDragStart,
          onDragEnd: onDragEnd,
          canTransform: canTransform,
          child: child,
        ),
        super(key: key);

  late final Widget _widget;
  @override
  Widget build(BuildContext context) {
    return _widget;
  }
}

class DraggableBase extends StatefulWidget {
  const DraggableBase({
    super.key,
    required this.child,
    required this.size,
    this.onDelete,
    this.onDragStart,
    this.onDragEnd,
    this.canTransform = false,
  });
  final Widget child;
  final Size size;
  final VoidCallback? onDelete;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final bool canTransform;

  @override
  State<DraggableBase> createState() => _DraggableBaseState();
}

class _DraggableBaseState extends State<DraggableBase> {
  ValueNotifier<Matrix4> notifier = ValueNotifier(Matrix4.identity());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: AnimatedBuilder(
        animation: notifier,
        builder: (ctx, child) {
          return FittedBox(
            child: Transform(
              transform: notifier.value,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.canTransform ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: MatrixGestureDetector(
                  onLayerTapped: () => widget.onDragStart?.call(),
                  onMatrixUpdate: (m, tm, sm, rm) {
                    widget.canTransform ? notifier.value = m : null;
                  },
                  onDragStart: () {
                    widget.onDragStart?.call();
                  },
                  onDragEnd: () {
                    widget.onDragEnd?.call();
                  },
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
