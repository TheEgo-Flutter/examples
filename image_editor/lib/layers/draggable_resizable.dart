import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class DragUpdate {
  const DragUpdate({
    required this.angle,
    required this.position,
    required this.size,
    required this.constraints,
  });

  final double angle;
  final Offset position;
  final Size size;
  final Size constraints;
}

class DraggableResizable extends StatefulWidget {
  DraggableResizable({
    Key? key,
    required this.child,
    required this.size,
    BoxConstraints? constraints,
    this.onUpdate,
    this.onLayerTapped,
    this.onEdit,
    this.onDelete,
    this.canTransform = false,
  })  : constraints = constraints ?? BoxConstraints.loose(Size.infinite),
        super(key: key);

  final Widget child;
  final ValueSetter<DragUpdate>? onUpdate;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onLayerTapped;
  final bool canTransform;
  final Size size;
  final BoxConstraints constraints;

  @override
  State<DraggableResizable> createState() => _DraggableResizableState();
}

class _DraggableResizableState extends State<DraggableResizable> {
  late Size size;
  late BoxConstraints constraints;
  double angle = 0;
  Offset position = Offset.zero;

  @override
  void initState() {
    super.initState();
    size = widget.size;
    constraints = const BoxConstraints.expand(width: 1, height: 1);
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = widget.size.width / widget.size.height;
    return LayoutBuilder(
      builder: (context, constraints) {
        position = position == Offset.zero
            ? Offset(
                constraints.maxWidth / 2 - (size.width / 2),
                constraints.maxHeight / 2 - (size.height / 2),
              )
            : position;

        final normalizedWidth = size.width;
        final normalizedHeight = normalizedWidth / aspectRatio;
        final newSize = Size(normalizedWidth, normalizedHeight);

        if (widget.constraints.isSatisfiedBy(newSize)) size = newSize;

        final normalizedLeft = position.dx;
        final normalizedTop = position.dy;

        if (this.constraints != constraints) {
          this.constraints = constraints;
        }

        return Stack(
          children: <Widget>[
            Positioned(
              top: normalizedTop,
              left: normalizedLeft,
              child: _DraggablePoint(
                onDrag: widget.canTransform
                    ? (d) {
                        log('onDrag');
                        setState(() {
                          position = Offset(position.dx + d.dx, position.dy + d.dy);
                        });
                      }
                    : null,
                onScale: widget.canTransform
                    ? (s) {
                        log('onScale');

                        final updatedSize = Size(
                          widget.size.width * s,
                          widget.size.height * s,
                        );

                        if (updatedSize.width < 64 || updatedSize.height < 64) return;

                        if (updatedSize.width > constraints.maxWidth || updatedSize.height > constraints.maxHeight) {
                          return;
                        }

                        final midX = position.dx + (size.width / 2);
                        final midY = position.dy + (size.height / 2);
                        final updatedPosition = Offset(
                          midX - (updatedSize.width / 2),
                          midY - (updatedSize.height / 2),
                        );

                        setState(() {
                          size = updatedSize;
                          position = updatedPosition;
                        });
                      }
                    : null,
                onRotate: widget.canTransform
                    ? (a) {
                        log('onRotate');
                        setState(() {
                          angle = a;
                        });
                      }
                    : null,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..scale(1.0)
                    ..rotateZ(angle),
                  child: Container(
                    height: normalizedHeight,
                    width: normalizedWidth,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 2,
                        color: widget.canTransform ? Colors.blue : Colors.transparent,
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DraggablePoint extends StatefulWidget {
  _DraggablePoint({
    Key? key,
    required this.child,
    this.onDrag,
    this.onScale,
    this.onRotate,
  }) : super(key: key);

  final Widget child;
  final ValueSetter<Offset>? onDrag;
  final ValueSetter<double>? onScale;
  final ValueSetter<double>? onRotate;

  @override
  _DraggablePointState createState() => _DraggablePointState();
}

class _DraggablePointState extends State<_DraggablePoint> {
  Offset initPoint = Offset.zero;
  double angle = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        initPoint = details.localFocalPoint;
      },
      onScaleUpdate: (details) {
        final dx = details.localFocalPoint.dx - initPoint.dx;
        final dy = details.localFocalPoint.dy - initPoint.dy;

        final angleInRadians = -angle * (math.pi / 180.0);
        final rotatedDx = dx * math.cos(angleInRadians) - dy * math.sin(angleInRadians);
        final rotatedDy = dx * math.sin(angleInRadians) + dy * math.cos(angleInRadians);

        initPoint = details.localFocalPoint;
        widget.onDrag?.call(Offset(rotatedDx, rotatedDy));

        if (details.pointerCount > 1) {
          widget.onScale?.call(details.scale);
          widget.onRotate?.call(details.rotation);
        }
      },
      child: widget.child,
    );
  }
}
