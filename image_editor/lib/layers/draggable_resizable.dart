import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/layer.dart';
import '../image_editor_plus.dart';

class DraggableResizable extends StatefulWidget {
  DraggableResizable({
    Key? key,
    required this.layer,
    BoxConstraints? constraints,
    this.onLayerTapped,
    this.onDelete,
    this.onDragStart,
    this.onDragEnd,
    this.canTransform = false,
  })  : constraints = constraints ?? BoxConstraints.loose(Size.infinite),
        super(key: key);
  final LayerData layer;
  final VoidCallback? onDelete;
  final VoidCallback? onLayerTapped;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  final bool canTransform;
  final BoxConstraints constraints;

  @override
  State<DraggableResizable> createState() => _DraggableResizableState();
}

class _DraggableResizableState extends State<DraggableResizable> {
  late Size size;
  late BoxConstraints constraints;
  double angle = 0;
  Offset position = Offset.zero;
  bool isCenteredHorizontally = false; // add this line
  bool isCenteredVertically = false; // and this line
  @override
  void initState() {
    super.initState();
    size = widget.layer.size;
    constraints = widget.constraints;
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = size.width / size.height;
    return LayoutBuilder(
      builder: (context, constraints) {
        //print one line constraint
        print('${constraints.maxWidth} ${constraints.maxHeight}');

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
            if (selectedAssetId == widget.layer.key) ...[
              Positioned(
                top: constraints.maxHeight / 2,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  color: isCenteredVertically ? Colors.red : Colors.transparent,
                ),
              ),
              Positioned(
                left: constraints.maxWidth / 2,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1,
                  color: isCenteredHorizontally ? Colors.red : Colors.transparent,
                ),
              )
            ],
            Positioned(
              top: normalizedTop,
              left: normalizedLeft,
              child: _DraggablePoint(
                onDragStart: () => widget.onDragStart?.call(),
                onDragEnd: () => widget.onDragEnd?.call(),
                onDrag: widget.canTransform
                    ? (d) {
                        setState(() {
                          position = Offset(position.dx + d.dx, position.dy + d.dy);
                          isCenteredHorizontally = checkIfCenteredHorizontally(position, size, constraints.maxWidth);
                          isCenteredVertically = checkIfCenteredVertically(position, size, constraints.maxHeight);
                        });
                      }
                    : null,
                onScale: widget.canTransform
                    ? (s) {
                        log('onScale');

                        final updatedSize = Size(
                          size.width * s,
                          size.height * s,
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
                    child: widget.layer.object,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool checkIfCenteredHorizontally(Offset position, Size size, double width) {
    final centerX = width / 2;
    final widgetCenterX = position.dx + size.width / 2;
    return (centerX - widgetCenterX).abs() < 5;
  }

  bool checkIfCenteredVertically(Offset position, Size size, double height) {
    final centerY = height / 2;
    final widgetCenterY = position.dy + size.height / 2;
    return (centerY - widgetCenterY).abs() < 5;
  }
}

class _DraggablePoint extends StatefulWidget {
  _DraggablePoint({
    Key? key,
    required this.child,
    this.onDrag,
    this.onDragStart,
    this.onDragEnd,
    this.onScale,
    this.onRotate,
  }) : super(key: key);

  final Widget child;
  final ValueSetter<Offset>? onDrag;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
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
        widget.onDragStart?.call();
      },
      onScaleEnd: (details) {
        widget.onDragEnd?.call();
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

// 
