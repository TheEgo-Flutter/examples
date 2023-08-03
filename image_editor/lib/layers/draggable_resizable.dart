import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../layers/layer.dart';
import 'matrix_gesture_detector.dart';

class DraggableResizable extends StatelessWidget {
  DraggableResizable.background({
    required Key key,
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
    required LayerData layer,
    VoidCallback? onDragStart,
    VoidCallback? onDragEnd,
    VoidCallback? onDelete,
    bool canTransform = false,
  })  : _widget = DraggableBase(
          key: key,
          size: layer.size,
          onDragStart: onDragStart,
          onDragEnd: onDragEnd,
          canTransform: canTransform,
          child: layer.object,
        ),
        // = Container(
        //         width: layer.size.width,
        //         height: layer.size.height,
        //         decoration: BoxDecoration(
        //           border: Border.all(
        //             width: 2,
        //             color: canTransform ? Colors.blue : Colors.transparent,
        //           ),
        //         ),
        //         child: ,
        //       ),
        super(key: key);

  late final Widget _widget;
  @override
  Widget build(BuildContext context) {
    return _widget;
  }
}

class DraggableBase extends StatefulWidget {
  DraggableBase({
    required key,
    required this.child,
    required this.size,
    this.onDelete,
    this.onDragStart,
    this.onDragEnd,
    this.canTransform = false,
  }) : super(key: key);
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
    return MatrixGestureDetector(
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
      child: AnimatedBuilder(
        animation: notifier,
        builder: (ctx, child) {
          return Transform(
            transform: notifier.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
