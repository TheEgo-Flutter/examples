import 'dart:math';

import 'package:flutter/material.dart';

class DragUpdate {
  const DragUpdate({
    required this.angle,
    required this.position,
    required this.size,
    required this.constraints,
  });

  /// The angle of the draggable asset.
  final double angle;

  /// The position of the draggable asset.
  final Offset position;

  /// The size of the draggable asset.
  final Size size;

  /// The constraints of the parent view.
  final Size constraints;
}

const _cornerDiameter = 22.0;
const _floatingActionDiameter = 18.0;
const _floatingActionPadding = 24.0;

class DraggableResizable extends StatefulWidget {
  /// {@macro draggable_resizable}
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

  /// The child which will be draggable/resizable.
  final Widget child;

  // final VoidCallback? onTap;

  /// Drag/Resize value setter.
  final ValueSetter<DragUpdate>? onUpdate;

  /// Delete callback
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onLayerTapped;

  /// Whether or not the asset can be dragged or resized.
  /// Defaults to false.
  final bool canTransform;

  /// The child's original size.
  final Size size;

  /// The child's constraints.
  /// Defaults to [BoxConstraints.loose(Size.infinite)].
  final BoxConstraints constraints;

  @override
  State<DraggableResizable> createState() => _DraggableResizableState();
}

class _DraggableResizableState extends State<DraggableResizable> {
  late Size size;
  late BoxConstraints constraints;
  late double angle;
  late double angleDelta;
  late double baseAngle;

  bool get isTouchInputSupported => true;

  Offset position = Offset.zero;

  @override
  void initState() {
    super.initState();
    size = widget.size;
    constraints = const BoxConstraints.expand(width: 1, height: 1);
    angle = 0;
    baseAngle = 0;
    angleDelta = 0;
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

        // // print(a.localToGlobal(Offset.zero));

        void onUpdate() {
          final normalizedPosition = Offset(
            normalizedLeft + (_floatingActionPadding / 2) + (_cornerDiameter / 2),
            normalizedTop + (_floatingActionPadding / 2) + (_cornerDiameter / 2),
          );
          widget.onUpdate?.call(
            DragUpdate(
              position: normalizedPosition,
              size: size,
              constraints: Size(constraints.maxWidth, constraints.maxHeight),
              angle: angle,
            ),
          );
        }

        final decoratedChild = Container(
          key: const Key('draggableResizable_child_container'),
          alignment: Alignment.center,
          height: normalizedHeight + _cornerDiameter + _floatingActionPadding,
          width: normalizedWidth + _cornerDiameter + _floatingActionPadding,
          child: Container(
            height: normalizedHeight,
            width: normalizedWidth,
            decoration: BoxDecoration(
              border: Border.all(
                width: 2,
                color: widget.canTransform ? Colors.blue : Colors.transparent,
              ),
            ),
            child: Center(child: widget.child),
          ),
        );

        final deleteButton = _FloatingActionIcon(
          key: const Key('draggableResizable_delete_floatingActionIcon'),
          iconData: Icons.delete,
          onTap: widget.onDelete,
        );

        if (this.constraints != constraints) {
          this.constraints = constraints;
          onUpdate();
        }

        return Stack(
          children: <Widget>[
            Positioned(
              top: normalizedTop,
              left: normalizedLeft,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(1.0)
                  ..rotateZ(angle),
                child: _DraggablePoint(
                  key: const Key('draggableResizable_child_draggablePoint'),
                  onTap: onUpdate,
                  onDrag: (d) {
                    setState(() {
                      bool isCrush = false;
                      double dx = d.dx * cos(angle) - d.dy * sin(angle);
                      double dy = d.dx * sin(angle) + d.dy * cos(angle);
                      if (position.dx + dx < 0 && dx < 0) {
                        position = Offset(0, position.dy + dy);
                        isCrush = true;
                      }
                      if (position.dy + dy < 0 && dy < 0) {
                        position = Offset(position.dx + dx, 0);
                        isCrush = true;
                      }
                      if (position.dx > constraints.maxWidth - size.width && dx > 0) {
                        position = Offset(constraints.maxWidth - size.width, position.dy + dy);
                        isCrush = true;
                      }
                      if (position.dy > constraints.maxHeight - size.height && dy > 0) {
                        position = Offset(position.dx + dx, constraints.maxHeight - size.height);
                        isCrush = true;
                      }
                      if (!isCrush) {
                        position = Offset(position.dx + dx, position.dy + dy);
                      }
                    });

                    onUpdate();
                  },
                  onScale: (s) {
                    // onDragBottomRight();
                    final updatedSize = Size(
                      widget.size.width * s,
                      widget.size.height * s,
                    );

                    if (s > 2.0) return;
                    if (updatedSize.width < 150 || updatedSize.height < 150) return;
                    if (updatedSize.width >= constraints.maxWidth || updatedSize.height >= constraints.maxHeight) {
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

                    onUpdate();
                  },
                  onRotate: (a) {
                    setState(() {
                      angle = a;
                    });
                    onUpdate();
                  },
                  child: Stack(
                    children: [
                      decoratedChild,
                      if (widget.canTransform && isTouchInputSupported) ...[
                        Positioned(
                          right: (normalizedWidth / 2) -
                              (_floatingActionDiameter / 2) +
                              (_cornerDiameter / 2) +
                              (_floatingActionPadding / 2),
                          child: deleteButton,
                        ),
                      ],
                    ],
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
  const _DraggablePoint({
    Key? key,
    required this.child,
    this.onDrag,
    this.onScale,
    this.onRotate,
    this.onTap,
  }) : super(key: key);

  final Widget child;

  final ValueSetter<Offset>? onDrag;
  final ValueSetter<double>? onScale;
  final ValueSetter<double>? onRotate;
  final VoidCallback? onTap;

  @override
  _DraggablePointState createState() => _DraggablePointState();
}

class _DraggablePointState extends State<_DraggablePoint> {
  late Offset initPoint;
  var baseScaleFactor = 1.0;
  var scaleFactor = 1.0;
  var baseAngle = 0.0;
  var angle = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onScaleStart: (details) {
        initPoint = details.localFocalPoint;
        if (details.pointerCount > 1) {
          baseAngle = angle;
          baseScaleFactor = scaleFactor;
          widget.onRotate?.call(baseAngle);
          widget.onScale?.call(baseScaleFactor);
        }
      },
      onScaleUpdate: (details) {
        final dx = details.localFocalPoint.dx - initPoint.dx;
        final dy = details.localFocalPoint.dy - initPoint.dy;
        initPoint = details.localFocalPoint;
        widget.onDrag?.call(Offset(dx, dy));
        if (details.pointerCount > 1) {
          scaleFactor = baseScaleFactor * details.scale;
          widget.onScale?.call(scaleFactor);
          angle = baseAngle + details.rotation;
          widget.onRotate?.call(angle);
        }
      },
      child: widget.child,
    );
  }
}

class _FloatingActionIcon extends StatelessWidget {
  const _FloatingActionIcon({
    Key? key,
    required this.iconData,
    this.onTap,
  }) : super(key: key);

  final IconData iconData;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.hardEdge,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _floatingActionDiameter,
          width: _floatingActionDiameter,
          child: Center(
            child: Icon(
              iconData,
              color: Colors.blue,
              size: 12,
            ),
          ),
        ),
      ),
    );
  }
}
